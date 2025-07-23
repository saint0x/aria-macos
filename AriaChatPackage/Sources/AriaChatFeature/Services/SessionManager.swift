import Foundation
import SwiftUI
import Combine

/// Manages user sessions and interactions with the SessionService
@MainActor
public class SessionManager: ObservableObject {
    public static let shared = SessionManager()
    
    @Published public private(set) var currentSessionId: String?
    @Published public private(set) var currentSession: SessionResponse?
    @Published public private(set) var isCreatingSession = false
    @Published public private(set) var sessionError: Error?
    
    private let apiClient = RESTAPIClient.shared
    
    private init() {}
    
    /// Creates a new session
    public func createSession() async throws -> String {
        isCreatingSession = true
        sessionError = nil
        
        defer {
            isCreatingSession = false
        }
        
        do {
            print("SessionManager: Creating session...")
            
            let request = CreateSessionRequest()
            
            print("SessionManager: Sending POST request to create session...")
            let response = try await apiClient.post(
                APIEndpoints.createSession,
                body: request,
                type: SessionResponse.self
            )
            
            print("SessionManager: Got response with session ID: \(response.id)")
            
            currentSessionId = response.id
            currentSession = response
            return response.id
        } catch {
            print("SessionManager: Error creating session: \(error)")
            sessionError = error
            throw error
        }
    }
    
    /// Gets the current session ID, creating a new one if needed
    public func getCurrentSessionId() async throws -> String {
        if let sessionId = currentSessionId {
            return sessionId
        }
        
        return try await createSession()
    }
    
    /// Get session details
    public func getSession(_ sessionId: String) async throws -> SessionResponse {
        do {
            print("SessionManager: Getting session \(sessionId)...")
            
            let response = try await apiClient.get(
                APIEndpoints.getSession(sessionId),
                type: SessionResponse.self
            )
            
            print("SessionManager: Got session details")
            
            // Update current session if it matches
            if sessionId == currentSessionId {
                currentSession = response
            }
            
            return response
        } catch {
            print("SessionManager: Error getting session: \(error)")
            sessionError = error
            throw error
        }
    }
    
    /// Clears the current session
    public func clearSession() {
        currentSessionId = nil
        currentSession = nil
        sessionError = nil
    }
    
    /// Loads conversation history for a specific session
    public func loadSessionHistory(_ sessionId: String) async throws -> ConversationHistoryResponse {
        let response = try await apiClient.get(
            APIEndpoints.getSessionHistory(sessionId),
            type: ConversationHistoryResponse.self
        )
        return response
    }
    
    /// Sets the current session without creating a new one
    public func setCurrentSession(_ sessionId: String) {
        currentSessionId = sessionId
        // Note: We don't set currentSession here as that would require an API call
        // The session details can be fetched separately if needed
    }
}