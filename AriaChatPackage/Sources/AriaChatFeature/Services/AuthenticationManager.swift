import Foundation
import AppKit

/// Manages authentication state and flows for the Aria application
@MainActor
public class AuthenticationManager: ObservableObject {
    public static let shared = AuthenticationManager()
    
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var userEmail: String?
    @Published public private(set) var userId: String?
    @Published public private(set) var authError: Error?
    @Published public private(set) var isLoading = false
    
    private let configManager = ConfigManager.shared
    private let keychainService = KeychainService.shared
    private let apiClient = RESTAPIClient.shared
    
    private init() {}
    
    /// Initialize authentication state on app launch
    public func initialize() async {
        print("AuthenticationManager: Initializing")
        
        do {
            // Load configuration
            try await configManager.loadConfig()
            
            // Check authentication status
            await checkAuthenticationStatus()
            
            print("AuthenticationManager: Initialized successfully")
        } catch {
            print("AuthenticationManager: Initialization failed: \(error)")
            authError = error
        }
    }
    
    /// Check current authentication status
    public func checkAuthenticationStatus() async {
        guard let config = configManager.config,
              let auth = config.auth,
              auth.linked else {
            isAuthenticated = false
            userEmail = nil
            userId = nil
            return
        }
        
        // Check if tokens are valid
        do {
            if let accessRef = auth.accessTokenRef,
               let refreshRef = auth.refreshTokenRef {
                
                let (_, _) = try keychainService.retrieveTokenPair(
                    accessRef: accessRef,
                    refreshRef: refreshRef
                )
                
                // Check if token is expired
                if let expiresAt = auth.expiresAt, expiresAt <= Date() {
                    print("AuthenticationManager: Access token expired, attempting refresh")
                    try await refreshTokens()
                } else {
                    // Token is valid
                    isAuthenticated = true
                    userEmail = auth.userEmail
                    userId = auth.userId
                    print("AuthenticationManager: User authenticated as \(auth.userEmail ?? "unknown")")
                }
            } else {
                // No token references
                isAuthenticated = false
                userEmail = nil
                userId = nil
            }
        } catch {
            print("AuthenticationManager: Error checking auth status: \(error)")
            authError = error
            isAuthenticated = false
            userEmail = nil
            userId = nil
        }
    }
    
    /// Start the authentication process by opening the browser
    public func startAuthFlow() async {
        print("AuthenticationManager: Starting auth flow")
        
        guard let loginURL = configManager.getAuthLoginURL() else {
            authError = AuthError.invalidConfiguration
            return
        }
        
        // Open browser to auth URL
        NSWorkspace.shared.open(loginURL)
        print("AuthenticationManager: Opened browser to \(loginURL)")
    }
    
    /// Handle authentication callback with token (from deep link)
    public func handleAuthCallback(token: String) async {
        print("AuthenticationManager: Handling auth callback")
        isLoading = true
        authError = nil
        
        do {
            // Decode JWT to get user info
            let userInfo = try decodeJWT(token)
            
            // Store tokens in keychain
            let (accessRef, refreshRef) = try keychainService.storeTokenPair(
                accessToken: token,
                refreshToken: userInfo.refreshToken ?? ""
            )
            
            // Update configuration
            var authConfig = AuthConfig()
            authConfig.linked = true
            authConfig.linkedAt = Date()
            authConfig.userEmail = userInfo.email
            authConfig.userId = userInfo.userId
            authConfig.accessTokenRef = accessRef
            authConfig.refreshTokenRef = refreshRef
            authConfig.expiresAt = userInfo.expiresAt
            
            try await configManager.updateAuth(authConfig)
            
            // Update state
            isAuthenticated = true
            userEmail = userInfo.email
            userId = userInfo.userId
            
            print("AuthenticationManager: Authentication successful for \(userInfo.email)")
            
        } catch {
            print("AuthenticationManager: Auth callback failed: \(error)")
            authError = error
        }
        
        isLoading = false
    }
    
    /// Refresh expired tokens
    public func refreshTokens() async throws {
        print("AuthenticationManager: Refreshing tokens")
        
        guard let config = configManager.config,
              let auth = config.auth,
              let refreshRef = auth.refreshTokenRef else {
            throw AuthError.noRefreshToken
        }
        
        let refreshToken = try keychainService.retrieveToken(for: refreshRef)
        
        // Make refresh request to API
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        let response = try await apiClient.refreshToken(request)
        
        // Update tokens in keychain
        if let accessRef = auth.accessTokenRef {
            try keychainService.updateToken(response.accessToken, for: accessRef)
        }
        
        if let newRefreshToken = response.refreshToken {
            try keychainService.updateToken(newRefreshToken, for: refreshRef)
        }
        
        // Update config with new expiration
        var updatedAuth = auth
        updatedAuth.expiresAt = response.expiresAt
        try await configManager.updateAuth(updatedAuth)
        
        print("AuthenticationManager: Tokens refreshed successfully")
    }
    
    /// Sign out the current user
    public func signOut() async {
        print("AuthenticationManager: Signing out")
        
        do {
            // Clear tokens from keychain
            try keychainService.clearAllTokens()
            
            // Clear auth from config
            try await configManager.updateAuth(AuthConfig())
            
            // Update state
            isAuthenticated = false
            userEmail = nil
            userId = nil
            authError = nil
            
            print("AuthenticationManager: Sign out successful")
            
        } catch {
            print("AuthenticationManager: Sign out error: \(error)")
            authError = error
        }
    }
    
    /// Get current access token for API requests
    public func getAccessToken() async -> String? {
        guard let config = configManager.config,
              let auth = config.auth,
              let accessRef = auth.accessTokenRef else {
            return nil
        }
        
        do {
            // Check if token is expired
            if let expiresAt = auth.expiresAt, expiresAt <= Date() {
                try await refreshTokens()
                // Re-fetch after refresh
                guard let updatedConfig = configManager.config,
                      let updatedAuth = updatedConfig.auth,
                      let updatedAccessRef = updatedAuth.accessTokenRef else {
                    return nil
                }
                return try keychainService.retrieveToken(for: updatedAccessRef)
            } else {
                return try keychainService.retrieveToken(for: accessRef)
            }
        } catch {
            print("AuthenticationManager: Error getting access token: \(error)")
            return nil
        }
    }
    
    /// Get authorization header for API requests
    public func getAuthorizationHeader() async -> String? {
        guard let token = await getAccessToken() else {
            return nil
        }
        return "Bearer \(token)"
    }
    
    // MARK: - Private Methods
    
    private func decodeJWT(_ token: String) throws -> JWTUserInfo {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            throw AuthError.invalidJWT
        }
        
        let payload = parts[1]
        guard let data = Data(base64Encoded: payload.padding(to: 4)) else {
            throw AuthError.invalidJWT
        }
        
        let claims = try JSONDecoder().decode(JWTClaims.self, from: data)
        
        return JWTUserInfo(
            userId: claims.sub,
            email: claims.email,
            expiresAt: Date(timeIntervalSince1970: TimeInterval(claims.exp)),
            refreshToken: nil // Will be provided separately
        )
    }
}

// MARK: - Data Models

private struct JWTClaims: Codable {
    let sub: String // user_id
    let email: String
    let exp: Int64 // expiration timestamp
}

private struct JWTUserInfo {
    let userId: String
    let email: String
    let expiresAt: Date
    let refreshToken: String?
}


// MARK: - String Extension for Base64 Padding

private extension String {
    func padding(to length: Int) -> String {
        let remainder = self.count % length
        if remainder == 0 { return self }
        return self + String(repeating: "=", count: length - remainder)
    }
}

/// Authentication-related errors
public enum AuthError: Error, LocalizedError {
    case invalidConfiguration
    case invalidJWT
    case noRefreshToken
    case tokenExpired
    case authenticationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid authentication configuration"
        case .invalidJWT:
            return "Invalid JWT token format"
        case .noRefreshToken:
            return "No refresh token available"
        case .tokenExpired:
            return "Authentication token has expired"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        }
    }
}