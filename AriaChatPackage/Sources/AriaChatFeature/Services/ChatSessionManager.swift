import Foundation
import SwiftUI
import Combine

/// Manages chat sessions with type-safe operations
@MainActor
public class ChatSessionManager: ObservableObject {
    public static let shared = ChatSessionManager()
    
    @Published public private(set) var sessions: [SessionListItem] = []
    @Published public private(set) var isLoadingSessions = false
    @Published public private(set) var sessionError: Error?
    @Published public private(set) var hasMoreSessions = false
    
    private let apiClient = RESTAPIClient.shared
    private let pageSize = 20
    private var currentOffset = 0
    
    // Cache for session titles to avoid repeated API calls
    private var sessionTitleCache: [String: String] = [:]
    
    private init() {}
    
    /// Load chat sessions with pagination support
    public func loadSessions(refresh: Bool = false) async throws {
        if refresh {
            sessions = []
            currentOffset = 0
            sessionTitleCache.removeAll()
        }
        
        isLoadingSessions = true
        sessionError = nil
        
        defer {
            isLoadingSessions = false
        }
        
        print("ChatSessionManager: Loading sessions...")
        
        do {
            let queryItems = APIEndpoints.QueryParams.listTasks(
                limit: pageSize,
                offset: currentOffset
            )
            
            let response = try await apiClient.get(
                APIEndpoints.listTasks, // This actually fetches sessions
                queryItems: queryItems,
                type: SessionsListResponse.self
            )
            
            print("ChatSessionManager: Loaded \(response.data.count) sessions")
            
            if refresh {
                self.sessions = response.data
            } else {
                self.sessions.append(contentsOf: response.data)
            }
            
            // Update pagination state
            currentOffset += response.data.count
            self.hasMoreSessions = response.data.count == pageSize
            
        } catch {
            print("ChatSessionManager: Error loading sessions: \(error)")
            self.sessionError = error
            throw error
        }
    }
    
    /// Load more sessions if available
    public func loadMoreSessions() async throws {
        guard hasMoreSessions, !isLoadingSessions else { return }
        try await loadSessions(refresh: false)
    }
    
    /// Get session title with intelligent fallback and caching
    public func getSessionTitle(for session: SessionListItem) async -> String {
        // Use existing title if available
        if let title = session.title, !title.isEmpty {
            return title
        }
        
        // Check cache first
        if let cachedTitle = sessionTitleCache[session.id] {
            return cachedTitle
        }
        
        // Generate title from conversation history
        let generatedTitle = await generateSessionTitle(for: session)
        sessionTitleCache[session.id] = generatedTitle
        return generatedTitle
    }
    
    /// Generate session title from first user message
    private func generateSessionTitle(for session: SessionListItem) async -> String {
        do {
            let historyResponse = try await SessionManager.shared.loadSessionHistory(session.id)
            
            // Find first user message
            if let firstTurn = historyResponse.data.turns.first {
                let userMessage = firstTurn.userMessage
                
                // Intelligent truncation - preserve meaningful content
                let title = truncateIntelligently(userMessage, maxLength: 50)
                print("ChatSessionManager: Generated title for session \(session.id): \(title)")
                return title
            }
            
        } catch {
            print("ChatSessionManager: Error generating title for session \(session.id): \(error)")
        }
        
        // Fallback to existing logic
        if session.messageCount > 0 {
            let messageText = session.messageCount == 1 ? "message" : "messages"
            return "Chat with \(session.messageCount) \(messageText)"
        } else {
            return "New chat session"
        }
    }
    
    /// Intelligently truncate text while preserving meaningful content
    private func truncateIntelligently(_ text: String, maxLength: Int) -> String {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanText.count <= maxLength {
            return cleanText
        }
        
        // Try to break at word boundaries
        let words = cleanText.components(separatedBy: " ")
        var result = ""
        
        for word in words {
            let testResult = result.isEmpty ? word : "\(result) \(word)"
            if testResult.count <= maxLength - 3 { // Leave room for "..."
                result = testResult
            } else {
                break
            }
        }
        
        return result.isEmpty ? String(cleanText.prefix(maxLength - 3)) + "..." : result + "..."
    }
    
    /// Get session metadata for display
    public func getSessionMetadata(for session: SessionListItem) -> (messageCount: String, lastAccessed: String) {
        let messageCount = "\(session.messageCount) messages"
        
        let lastAccessed: String
        if let date = session.lastAccessedAtDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.dateTimeStyle = .named
            lastAccessed = formatter.localizedString(for: date, relativeTo: Date())
        } else {
            lastAccessed = "Unknown"
        }
        
        return (messageCount: messageCount, lastAccessed: lastAccessed)
    }
    
    /// Map session status to enhanced status for UI
    public func mapSessionStatus(_ session: SessionListItem) -> (text: String, color: Color) {
        switch session.status.lowercased() {
        case "active":
            return ("Active", Color(hue: 120/360, saturation: 0.85, brightness: 0.85))
        case "completed":
            return ("Active", Color(hue: 120/360, saturation: 0.85, brightness: 0.85))
        case "failed":
            return ("Disconnected", Color(hue: 0/360, saturation: 0.85, brightness: 0.85))
        default:
            return ("Active", Color(hue: 120/360, saturation: 0.85, brightness: 0.85))
        }
    }
    
    /// Clear all sessions and cache
    public func clearSessions() {
        sessions = []
        hasMoreSessions = false
        sessionError = nil
        sessionTitleCache.removeAll()
    }
}