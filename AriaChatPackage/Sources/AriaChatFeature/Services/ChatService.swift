import Foundation
import SwiftUI
import Combine

/// Manages chat interactions and AI responses via REST API ExecuteTurn
@MainActor
public class ChatService: ObservableObject {
    public static let shared = ChatService()
    
    @Published public private(set) var isProcessing = false
    @Published public private(set) var processingComplete = false
    @Published public private(set) var chatError: Error?
    
    private let apiClient = RESTAPIClient.shared
    private let streamingClient = StreamingClient()
    private let sessionManager = SessionManager.shared
    
    // Active stream handle
    private var currentStreamHandle: StreamHandle?
    
    // Callback for handling turn output events
    public typealias TurnOutputHandler = @Sendable (TurnOutputEvent) -> Void
    
    private init() {}
    
    /// Execute a turn in the conversation
    public func executeTurn(input: String, onTurnOutput: @escaping TurnOutputHandler) async throws {
        isProcessing = true
        processingComplete = false
        chatError = nil
        
        defer {
            isProcessing = false
            processingComplete = true
        }
        
        // Cancel any existing stream
        if let handle = currentStreamHandle {
            await handle.cancel()
            currentStreamHandle = nil
        }
        
        // Get current session ID
        let sessionId: String
        
        do {
            sessionId = try await sessionManager.getCurrentSessionId()
        } catch {
            chatError = error
            throw error
        }
        
        do {
            // Prepare request
            let request = ExecuteTurnRequest(input: input)
            
            // Build SSE URL
            let host = ProcessInfo.processInfo.environment["ARIA_API_HOST"] ?? "localhost"
            let port = ProcessInfo.processInfo.environment["ARIA_API_PORT"] ?? "50052"
            let scheme = ProcessInfo.processInfo.environment["ARIA_API_SCHEME"] ?? "http"
            let urlString = "\(scheme)://\(host):\(port)/api/v1\(APIEndpoints.executeTurn(sessionId))"
            
            guard let url = URL(string: urlString) else {
                throw APIError.invalidResponse
            }
            
            // Convert request to JSON for POST body
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let jsonData = try encoder.encode(request)
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = jsonData
            
            print("ChatService: Starting SSE stream for turn execution...")
            
            // Start SSE stream
            currentStreamHandle = await streamingClient.streamWithRequest(
                request: urlRequest,
                onEvent: { [weak self] event in
                    await self?.handleStreamEvent(event, onTurnOutput: onTurnOutput)
                },
                onError: { [weak self] error in
                    Task { @MainActor in
                        self?.chatError = error
                        print("ChatService: Stream error: \(error)")
                    }
                }
            )
            
            // For SSE, we don't wait for completion as it's handled by the stream
            // The stream will continue until server closes it
            
        } catch {
            // If API fails, fall back to mock
            print("API request failed: \(error), using mock response")
            await simulateStreamingResponse(input: input, sessionId: sessionId, onTurnOutput: onTurnOutput)
        }
    }
    
    private func handleStreamEvent(_ event: SSEEvent, onTurnOutput: @escaping TurnOutputHandler) async {
        print("ChatService: Received SSE event type: \(event.type)")
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Parse the event based on type
        switch event.type {
        case "message":
            if let data = event.data.data(using: .utf8),
               let eventData = try? decoder.decode(SSEMessageEvent.self, from: data) {
                
                let msg = Message(
                    id: eventData.id,
                    role: mapStringToMessageRole(eventData.role),
                    content: eventData.content,
                    metadata: eventData.metadata
                )
                onTurnOutput(.message(msg))
            }
            
        case "tool_call":
            if let data = event.data.data(using: .utf8),
               let eventData = try? decoder.decode(SSEToolCallEvent.self, from: data) {
                
                // Convert AnyCodable to string parameters
                var params: [String: String] = [:]
                for (key, value) in eventData.parametersJson {
                    // AnyCodable wraps the actual value - we need to encode it as JSON
                    if let jsonData = try? JSONEncoder().encode(value),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        params[key] = jsonString
                    }
                }
                
                let call = ToolCall(
                    id: UUID().uuidString, // Generate ID since it's not in the event
                    toolName: eventData.toolName,
                    parameters: params
                )
                onTurnOutput(.toolCall(call))
            }
            
        case "tool_result":
            if let data = event.data.data(using: .utf8),
               let eventData = try? decoder.decode(SSEToolResultEvent.self, from: data) {
                
                // Convert result JSON to string
                let output: String
                if let jsonData = try? JSONEncoder().encode(eventData.resultJson),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    output = jsonString
                } else {
                    output = "{}"
                }
                
                let result = ToolResult(
                    toolCallId: UUID().uuidString, // Generate ID since it's not in the event
                    toolName: eventData.toolName,
                    output: output,
                    success: eventData.success,
                    error: nil
                )
                onTurnOutput(.toolResult(result))
            }
            
        case "final_response":
            if let data = event.data.data(using: .utf8),
               let eventData = try? decoder.decode(SSEFinalResponseEvent.self, from: data) {
                
                onTurnOutput(.finalResponse(eventData.content))
            }
            
        case "error":
            print("ChatService: Received error event: \(event.data)")
            
        default:
            print("ChatService: Unknown event type: \(event.type)")
        }
    }
    
    private func mapStringToMessageRole(_ role: String) -> MessageRole {
        switch role.lowercased() {
        case "user":
            return .user
        case "assistant":
            return .assistant
        case "tool":
            return .tool
        case "system":
            return .system
        case "thought":
            return .thought
        default:
            return .assistant
        }
    }
    
    /// Cancel the current streaming operation
    public func cancelCurrentTurn() async {
        if let handle = currentStreamHandle {
            await handle.cancel()
            currentStreamHandle = nil
        }
        isProcessing = false
        processingComplete = true
    }
    
    // Mock implementation that simulates streaming
    private func simulateStreamingResponse(input: String, sessionId: String, onTurnOutput: @escaping TurnOutputHandler) async {
        // Simulate initial thinking
        onTurnOutput(.message(Message(
            id: UUID().uuidString,
            role: .thought,
            content: "Analyzing your request...",
            metadata: MessageMetadata(isStatus: true, isFinal: false, messageType: "status")
        )))
        
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        // Simulate tool call
        onTurnOutput(.toolCall(ToolCall(
            id: UUID().uuidString,
            toolName: "KnowledgeRetriever",
            parameters: ["query": input]
        )))
        
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s
        
        // Simulate tool result
        onTurnOutput(.toolResult(ToolResult(
            toolCallId: UUID().uuidString,
            toolName: "KnowledgeRetriever",
            output: "Found relevant information",
            success: true,
            error: nil
        )))
        
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        // Simulate final response
        onTurnOutput(.finalResponse("Based on my analysis, here's a response to your query: \(input)"))
    }
}

// MARK: - Turn Output Events

public enum TurnOutputEvent: Sendable {
    case message(Message)
    case toolCall(ToolCall)
    case toolResult(ToolResult)
    case finalResponse(String)
}

// MARK: - Message Types

public struct Message: Sendable {
    public let id: String
    public let role: MessageRole
    public let content: String
    public let metadata: MessageMetadata?
}

public struct ToolCall: Sendable {
    public let id: String
    public let toolName: String
    public let parameters: [String: String]
}

public struct ToolResult: Sendable {
    public let toolCallId: String
    public let toolName: String
    public let output: String
    public let success: Bool
    public let error: String?
}

// Message role enum
public enum MessageRole: Sendable {
    case system
    case user
    case assistant
    case thought
    case tool
}