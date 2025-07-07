import Foundation

/// Main REST API client for Aria HTTP endpoints
public actor RESTAPIClient {
    public static let shared = RESTAPIClient()
    
    private let baseURL: URL
    private let authBaseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        // Configure base URL from environment or defaults
        let host = ProcessInfo.processInfo.environment["ARIA_API_HOST"] ?? "localhost"
        let port = ProcessInfo.processInfo.environment["ARIA_API_PORT"] ?? "50052"
        let scheme = ProcessInfo.processInfo.environment["ARIA_API_SCHEME"] ?? "http"
        
        self.baseURL = URL(string: "\(scheme)://\(host):\(port)/api/v1")!
        self.authBaseURL = URL(string: "\(scheme)://\(host):\(port)/api")!
        
        // Configure URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        self.session = URLSession(configuration: config)
        
        // Configure JSON coders
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        // Keep default date strategy since server returns date strings
        
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        // Keep default date strategy
    }
    
    // MARK: - Request Methods
    
    /// Perform GET request
    public func get<T: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem]? = nil,
        type: T.Type
    ) async throws -> T {
        let url = buildURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        await addAuthHeaders(&request)
        
        return try await performRequest(request, type: type)
    }
    
    /// Perform POST request
    public func post<T: Decodable, U: Encodable>(
        _ path: String,
        body: U,
        type: T.Type
    ) async throws -> T {
        let url = buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(body)
        await addAuthHeaders(&request)
        
        return try await performRequest(request, type: type)
    }
    
    /// Perform POST request with no response body
    public func post<U: Encodable>(
        _ path: String,
        body: U
    ) async throws {
        let url = buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(body)
        await addAuthHeaders(&request)
        
        _ = try await performRequestNoResponse(request)
    }
    
    /// Perform POST request with no body
    public func post(_ path: String) async throws {
        let url = buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        await addAuthHeaders(&request)
        
        _ = try await performRequestNoResponse(request)
    }
    
    // MARK: - Auth-specific Methods
    
    /// Refresh authentication tokens
    public func refreshToken(_ request: RefreshTokenRequest) async throws -> RefreshTokenResponse {
        let url = buildAuthURL(path: APIEndpoints.refreshToken)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try encoder.encode(request)
        
        return try await performRequest(urlRequest, type: RefreshTokenResponse.self)
    }
    
    // MARK: - Private Methods
    
    private func buildURL(path: String, queryItems: [URLQueryItem]? = nil) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
        components.path = components.path + path
        components.queryItems = queryItems
        return components.url!
    }
    
    private func buildAuthURL(path: String, queryItems: [URLQueryItem]? = nil) -> URL {
        var components = URLComponents(url: authBaseURL, resolvingAgainstBaseURL: true)!
        components.path = components.path + path
        components.queryItems = queryItems
        return components.url!
    }
    
    private func addAuthHeaders(_ request: inout URLRequest) async {
        // Add authentication header if available
        if let authHeader = await AuthenticationManager.shared.getAuthorizationHeader() {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest, type: T.Type) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        do {
            // Try to decode as wrapped response first
            if let wrappedResponse = try? decoder.decode(APIResponse<T>.self, from: data) {
                return wrappedResponse.data
            }
            // Fall back to direct decoding
            return try decoder.decode(type, from: data)
        } catch {
            print("Decoding error: \(error)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw APIError.decodingError(error)
        }
    }
    
    private func performRequestNoResponse(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return data
    }
}

// MARK: - Request/Response Models

public struct RefreshTokenRequest: Codable, Sendable {
    public let refreshToken: String
    
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct RefreshTokenResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresAt: Date
    
    public init(accessToken: String, refreshToken: String?, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}

// MARK: - API Errors

public enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case streamingError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let data):
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            return "HTTP \(statusCode): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .streamingError(let message):
            return "Streaming error: \(message)"
        }
    }
}