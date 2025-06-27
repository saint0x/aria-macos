import Foundation
import SwiftUI
import Combine
import GRPC

/// Manages chat interactions and AI responses via AriaRuntime.ExecuteTurn
@MainActor
public class ChatService: ObservableObject {
    public static let shared = ChatService()
    
    @Published public private(set) var isProcessing = false
    @Published public private(set) var processingComplete = false
    @Published public private(set) var chatError: Error?
    
    private let client = AriaRuntimeClient.shared
    private let sessionManager = SessionManager.shared
    
    // Callback for handling turn output events
    public typealias TurnOutputHandler = (TurnOutputEvent) -> Void
    
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
        
        // Get current session ID
        let sessionId: String
        
        do {
            sessionId = try await sessionManager.getCurrentSessionId()
        } catch {
            chatError = error
            throw error
        }
        
        do {
            // Create the gRPC client
            let sessionClient = try await client.makeSessionServiceClient()
            var request = Aria_ExecuteTurnRequest()
            request.sessionID = sessionId
            request.input = input
            
            // Stream the response using callback API
            let call = sessionClient.executeTurn(request) { [weak self] output in
                guard let self = self else { return }
                Task { @MainActor in
                    switch output.event {
                    case .message(let message):
                        let msg = Message(
                            id: message.id,
                            role: self.mapProtoMessageRole(message.role),
                            content: message.content
                        )
                        onTurnOutput(.message(msg))
                        
                    case .toolCall(let toolCall):
                        let call = ToolCall(
                            id: UUID().uuidString,
                            toolName: toolCall.toolName,
                            parameters: ["json": toolCall.parametersJson]
                        )
                        onTurnOutput(.toolCall(call))
                        
                    case .toolResult(let toolResult):
                        let result = ToolResult(
                            toolCallId: UUID().uuidString,
                            toolName: toolResult.toolName,
                            output: toolResult.resultJson,
                            success: toolResult.success,
                            error: toolResult.errorMessage
                        )
                        onTurnOutput(.toolResult(result))
                        
                    case .finalResponse(let response):
                        onTurnOutput(.finalResponse(response))
                        
                    case .none:
                        break
                    }
                }
            }
            
            // Wait for the call to complete
            _ = try await call.status.get()
            
        } catch {
            // If gRPC fails (e.g., server not running), fall back to mock
            if (error as? GRPCStatus)?.code == .unavailable {
                print("gRPC server unavailable, using mock response")
                await simulateStreamingResponse(input: input, sessionId: sessionId, onTurnOutput: onTurnOutput)
            } else {
                chatError = error
                throw error
            }
        }
    }
    
    private func mapProtoMessageRole(_ role: Aria_MessageRole) -> MessageRole {
        switch role {
        case .user:
            return .user
        case .assistant:
            return .assistant
        case .tool:
            return .tool
        case .system:
            return .system
        case .UNRECOGNIZED:
            return .assistant
        default:
            return .assistant
        }
    }
    
    // Mock implementation that simulates streaming
    private func simulateStreamingResponse(input: String, sessionId: String, onTurnOutput: @escaping TurnOutputHandler) async {
        // Simulate initial thinking
        onTurnOutput(.message(Message(
            id: UUID().uuidString,
            role: .thought,
            content: "Analyzing your request..."
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

public enum TurnOutputEvent {
    case message(Message)
    case toolCall(ToolCall)
    case toolResult(ToolResult)
    case finalResponse(String)
}

// MARK: - Message Types

public struct Message {
    public let id: String
    public let role: MessageRole
    public let content: String
}

public struct ToolCall {
    public let id: String
    public let toolName: String
    public let parameters: [String: String]
}

public struct ToolResult {
    public let toolCallId: String
    public let toolName: String
    public let output: String
    public let success: Bool
    public let error: String?
}

// Message role enum
public enum MessageRole {
    case system
    case user
    case assistant
    case thought
    case tool
}