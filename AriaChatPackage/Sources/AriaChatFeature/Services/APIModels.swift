import Foundation

// MARK: - API Response Wrapper

/// Generic wrapper for API responses that contain a "data" field
public struct APIResponse<T: Decodable>: Decodable {
    public let data: T
}

extension APIResponse: Encodable where T: Encodable {}

// Make APIResponse Sendable when T is Sendable
extension APIResponse: Sendable where T: Sendable {}

// MARK: - Session Models

// For session creation, we now send an empty object
public struct CreateSessionRequest: Codable, Sendable {
    public init() {}
}

public struct SessionResponse: Codable, Sendable {
    public let id: String
    public let userId: String
    public let createdAt: String  // Server returns RFC3339 string
    public let contextData: [String: AnyCodable]
    public let status: String
    
    // Computed property to get Date
    public var createdAtDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt)
    }
}

// MARK: - Turn Models

public struct ExecuteTurnRequest: Codable, Sendable {
    public let input: String
    
    public init(input: String) {
        self.input = input
    }
}

// MARK: - SSE Event Models

public struct MessageMetadata: Codable, Sendable {
    public let isStatus: Bool
    public let isFinal: Bool
    public let messageType: String
}

public struct SSEMessageEvent: Codable, Sendable {
    public let type: String
    public let id: String
    public let role: String
    public let content: String
    public let createdAt: String
    public let metadata: MessageMetadata?
}

public struct SSEToolCallEvent: Codable, Sendable {
    public let type: String
    public let toolName: String
    public let parametersJson: [String: AnyCodable]
}

public struct SSEToolResultEvent: Codable, Sendable {
    public let type: String
    public let toolName: String
    public let resultJson: [String: AnyCodable]
    public let success: Bool
}

public struct SSEFinalResponseEvent: Codable, Sendable {
    public let type: String
    public let content: String
}

// MARK: - Task Models

public struct CreateTaskRequest: Codable, Sendable {
    public let type: String
    public let payload: TaskPayload
    public let sessionId: String?
    
    public init(type: String, payload: TaskPayload, sessionId: String? = nil) {
        self.type = type
        self.payload = payload
        self.sessionId = sessionId
    }
}

public struct TaskPayload: Codable, Sendable {
    public let command: String?
    public let args: [String: AnyCodable]?
    
    public init(command: String? = nil, args: [String: AnyCodable]? = nil) {
        self.command = command
        self.args = args
    }
}

public struct TaskResponse: Codable, Sendable {
    public let id: String
    public let type: String
    public var status: String
    public let createdAt: Date
    public let updatedAt: Date
    public let sessionId: String?
    public let payload: TaskPayload?
    public let result: TaskResult?
}

public struct TaskResult: Codable, Sendable {
    public let output: String?
    public let error: String?
    public let exitCode: Int?
}

public struct ListTasksResponse: Codable, Sendable {
    public let tasks: [TaskResponse]
    public let nextPageToken: String?
}

// MARK: - Bundle Models

public struct UploadBundleRequest: Codable, Sendable {
    public let name: String
    public let data: String // Base64 encoded
    
    public init(name: String, data: String) {
        self.name = name
        self.data = data
    }
}

public struct UploadBundleResponse: Codable, Sendable {
    public let id: String
    public let size: Int64
    public let checksum: String
}

// MARK: - Helper Types

/// Type-erased Codable container for arbitrary JSON values
public struct AnyCodable: Codable, @unchecked Sendable {
    private let value: Any
    
    public var wrappedValue: Any {
        return value
    }
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}