import Foundation
import Security

/// Manages secure token storage in macOS Keychain
public final class KeychainService: @unchecked Sendable {
    public static let shared = KeychainService()
    
    private let serviceName = "com.aria.chat"
    private let accessGroup: String? = nil // Use default keychain access group
    
    private init() {}
    
    /// Store a token in the keychain and return a reference identifier
    public func storeToken(_ token: String, for tokenType: TokenType) throws -> String {
        let account = "\(tokenType.rawValue)_\(UUID().uuidString)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: token.data(using: .utf8) ?? Data(),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storageError(status)
        }
        
        print("KeychainService: Stored \(tokenType.rawValue) with reference: \(account.prefix(12))...")
        return account
    }
    
    /// Retrieve a token from the keychain using its reference identifier
    public func retrieveToken(for reference: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: reference,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.retrievalError(status)
        }
        
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataCorruption
        }
        
        return token
    }
    
    /// Update an existing token in the keychain
    public func updateToken(_ token: String, for reference: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: reference
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: token.data(using: .utf8) ?? Data()
        ]
        
        let status = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        
        guard status == errSecSuccess else {
            throw KeychainError.updateError(status)
        }
        
        print("KeychainService: Updated token for reference: \(reference.prefix(12))...")
    }
    
    /// Delete a token from the keychain
    public func deleteToken(for reference: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: reference
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionError(status)
        }
        
        print("KeychainService: Deleted token for reference: \(reference.prefix(12))...")
    }
    
    /// Check if a token exists in the keychain
    public func tokenExists(for reference: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: reference,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Clear all tokens for this app from the keychain
    public func clearAllTokens() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionError(status)
        }
        
        print("KeychainService: Cleared all tokens")
    }
    
    /// Store both access and refresh tokens, returning their references
    public func storeTokenPair(accessToken: String, refreshToken: String) throws -> (accessRef: String, refreshRef: String) {
        let accessRef = try storeToken(accessToken, for: .accessToken)
        let refreshRef = try storeToken(refreshToken, for: .refreshToken)
        return (accessRef, refreshRef)
    }
    
    /// Retrieve both access and refresh tokens using their references
    public func retrieveTokenPair(accessRef: String, refreshRef: String) throws -> (accessToken: String, refreshToken: String) {
        let accessToken = try retrieveToken(for: accessRef)
        let refreshToken = try retrieveToken(for: refreshRef)
        return (accessToken, refreshToken)
    }
}

/// Token types for keychain storage
public enum TokenType: String {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
}

/// Keychain-related errors
public enum KeychainError: Error, LocalizedError {
    case storageError(OSStatus)
    case retrievalError(OSStatus)
    case updateError(OSStatus)
    case deletionError(OSStatus)
    case dataCorruption
    case tokenNotFound
    
    public var errorDescription: String? {
        switch self {
        case .storageError(let status):
            return "Failed to store token in keychain: \(status)"
        case .retrievalError(let status):
            return "Failed to retrieve token from keychain: \(status)"
        case .updateError(let status):
            return "Failed to update token in keychain: \(status)"
        case .deletionError(let status):
            return "Failed to delete token from keychain: \(status)"
        case .dataCorruption:
            return "Token data is corrupted"
        case .tokenNotFound:
            return "Token not found in keychain"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .storageError, .retrievalError, .updateError, .deletionError:
            return "Check keychain access permissions and try again"
        case .dataCorruption:
            return "Re-authenticate to refresh tokens"
        case .tokenNotFound:
            return "Sign in again to generate new tokens"
        }
    }
}