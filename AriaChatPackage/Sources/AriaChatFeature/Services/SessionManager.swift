import Foundation
import SwiftUI
import Combine

/// Manages user sessions and interactions with the SessionService
@MainActor
public class SessionManager: ObservableObject {
    public static let shared = SessionManager()
    
    @Published public private(set) var currentSessionId: String?
    @Published public private(set) var isCreatingSession = false
    @Published public private(set) var sessionError: Error?
    
    private let client = AriaRuntimeClient.shared
    
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
            let sessionClient = try await client.makeSessionServiceClient()
            print("SessionManager: Got session client")
            let request = Aria_CreateSessionRequest()
            print("SessionManager: Sending CreateSession request...")
            let call = sessionClient.createSession(request)
            let response = try await call.response.get()
            print("SessionManager: Got response with session ID: \(response.id)")
            
            currentSessionId = response.id
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
    
    /// Clears the current session
    public func clearSession() {
        currentSessionId = nil
        sessionError = nil
    }
}