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

// MARK: - Tool & Agent Registry Models

public struct ToolRegistryResponse: Codable, Sendable {
    public let data: ToolRegistryData
}

public struct ToolRegistryData: Codable, Sendable {
    public let totalCount: Int
    public let tools: [Tool]
    
    private enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case tools
    }
}

public struct Tool: Codable, Sendable, Identifiable {
    public let name: String
    public let description: String
    public let category: String
    public let scope: String
    public let parameters: [String: AnyCodable]?
    public let capabilities: [String]
    public let securityLevel: String
    public let source: ToolSource
    public let version: String
    public let isAvailable: Bool
    
    public var id: String { name }
    
    private enum CodingKeys: String, CodingKey {
        case name, description, category, scope, parameters, capabilities, source, version
        case securityLevel = "security_level"
        case isAvailable = "is_available"
    }
}

public struct ToolSource: Codable, Sendable {
    public let type: String
    public let bundleId: String?
    public let bundlePath: String?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case bundleId = "bundle_id"
        case bundlePath = "bundle_path"
    }
}

public struct AgentRegistryResponse: Codable, Sendable {
    public let data: AgentRegistryData
}

public struct AgentRegistryData: Codable, Sendable {
    public let totalCount: Int
    public let agents: [Agent]
    
    private enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case agents
    }
}

public struct Agent: Codable, Sendable, Identifiable {
    public let name: String
    public let description: String
    public let capabilities: [String]
    public let supportedTasks: [String]
    public let source: ToolSource
    public let version: String
    public let isAvailable: Bool
    
    public var id: String { name }
    
    private enum CodingKeys: String, CodingKey {
        case name, description, capabilities, source, version
        case supportedTasks = "supported_tasks"
        case isAvailable = "is_available"
    }
}

// MARK: - Model Provider Models

public struct ModelProviderResponse: Codable, Sendable {
    public let data: ModelProviderData
}

public struct ModelProviderData: Codable, Sendable {
    public let providers: [ModelProvider]
    public let currentProvider: String?
    public let currentModel: String?
    
    private enum CodingKeys: String, CodingKey {
        case providers
        case currentProvider = "current_provider"
        case currentModel = "current_model"
    }
}

public struct ModelProvider: Codable, Sendable, Identifiable {
    public let name: String
    public let displayName: String
    public let description: String
    public let isConfigured: Bool
    public let isActive: Bool
    public let capabilities: ModelCapabilities
    public let configurationStatus: ConfigurationStatus
    
    public var id: String { name }
    
    private enum CodingKeys: String, CodingKey {
        case name, description, capabilities
        case displayName = "display_name"
        case isConfigured = "is_configured"
        case isActive = "is_active"
        case configurationStatus = "configuration_status"
    }
}

public struct ModelCapabilities: Codable, Sendable {
    public let supportsStreaming: Bool
    public let supportsFunctions: Bool
    public let supportsVision: Bool
    public let supportsJsonMode: Bool
    public let maxContextTokens: Int
    public let maxOutputTokens: Int
    
    private enum CodingKeys: String, CodingKey {
        case supportsStreaming = "supports_streaming"
        case supportsFunctions = "supports_functions"
        case supportsVision = "supports_vision"
        case supportsJsonMode = "supports_json_mode"
        case maxContextTokens = "max_context_tokens"
        case maxOutputTokens = "max_output_tokens"
    }
}

public struct ConfigurationStatus: Codable, Sendable {
    public let isConfigured: Bool
    public let hasApiKey: Bool
    public let lastHealthCheck: String?
    public let isHealthy: Bool
    public let errorMessage: String?
    
    private enum CodingKeys: String, CodingKey {
        case isConfigured = "is_configured"
        case hasApiKey = "has_api_key"
        case lastHealthCheck = "last_health_check"
        case isHealthy = "is_healthy"
        case errorMessage = "error_message"
    }
}

public struct ProviderModelsResponse: Codable, Sendable {
    public let data: ProviderModelsData
}

public struct ProviderModelsData: Codable, Sendable {
    public let models: [Model]
}

public struct Model: Codable, Sendable, Identifiable {
    public let name: String
    public let displayName: String
    public let description: String
    public let contextWindow: Int
    public let maxOutputTokens: Int
    public let inputPricing: ModelPricing
    public let outputPricing: ModelPricing
    public let capabilities: ModelCapabilities
    public let performance: ModelPerformance
    public let isAvailable: Bool
    
    public var id: String { name }
    
    private enum CodingKeys: String, CodingKey {
        case name, description, capabilities, performance
        case displayName = "display_name"
        case contextWindow = "context_window"
        case maxOutputTokens = "max_output_tokens"
        case inputPricing = "input_pricing"
        case outputPricing = "output_pricing"
        case isAvailable = "is_available"
    }
}

public struct ModelPricing: Codable, Sendable {
    public let perToken: Double
    public let currency: String
    
    private enum CodingKeys: String, CodingKey {
        case perToken = "per_token"
        case currency
    }
}

public struct ModelPerformance: Codable, Sendable {
    public let speed: String
    public let quality: String
    public let reasoning: String
}

public struct SelectModelRequest: Codable, Sendable {
    public let provider: String
    public let model: String
    public let setAsDefault: Bool
    
    private enum CodingKeys: String, CodingKey {
        case provider, model
        case setAsDefault = "set_as_default"
    }
    
    public init(provider: String, model: String, setAsDefault: Bool = true) {
        self.provider = provider
        self.model = model
        self.setAsDefault = setAsDefault
    }
}

public struct TestModelRequest: Codable, Sendable {
    public let provider: String
    public let model: String
    public let prompt: String
    public let temperature: Double?
    public let maxTokens: Int?
    
    private enum CodingKeys: String, CodingKey {
        case provider, model, prompt, temperature
        case maxTokens = "max_tokens"
    }
    
    public init(provider: String, model: String, prompt: String, temperature: Double? = nil, maxTokens: Int? = nil) {
        self.provider = provider
        self.model = model
        self.prompt = prompt
        self.temperature = temperature
        self.maxTokens = maxTokens
    }
}

// MARK: - Observability Models

public struct LogStreamEvent: Codable, Sendable {
    public let type: String
    public let entry: LogEntry
}

public struct LogEntry: Codable, Sendable, Identifiable {
    public let id: String
    public let timestamp: String
    public let level: String
    public let message: String
    public let target: String
    public let sessionId: String?
    public let userId: String?
    public let fields: [String: AnyCodable]
    public let metadata: LogMetadata
    
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, level, message, target, fields, metadata
        case sessionId = "session_id"
        case userId = "user_id"
    }
    
    public var timestampDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp)
    }
}

public struct LogMetadata: Codable, Sendable {
    public let component: String
    public let operation: String?
    public let durationMs: Int?
    
    private enum CodingKeys: String, CodingKey {
        case component, operation
        case durationMs = "duration_ms"
    }
}

public struct RecentLogsResponse: Codable, Sendable {
    public let data: RecentLogsData
}

public struct RecentLogsData: Codable, Sendable {
    public let logs: [LogEntry]
    public let totalCount: Int
    public let hasMore: Bool
    
    private enum CodingKeys: String, CodingKey {
        case logs
        case totalCount = "total_count"
        case hasMore = "has_more"
    }
}

public struct MetricsResponse: Codable, Sendable {
    public let data: MetricsData
}

public struct MetricsData: Codable, Sendable {
    public let timestamp: String
    public let system: SystemMetrics
    public let runtime: RuntimeMetrics
    public let database: DatabaseMetrics
    public let containers: ContainerMetrics
    public let llm: LLMMetrics
    
    public var timestampDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp)
    }
}

public struct SystemMetrics: Codable, Sendable {
    public let cpuUsagePercent: Double
    public let memoryUsageMb: Double
    public let memoryTotalMb: Double
    public let diskUsageGb: Double
    public let diskTotalGb: Double
    public let networkRxMb: Double
    public let networkTxMb: Double
    public let uptimeSeconds: Int
    
    private enum CodingKeys: String, CodingKey {
        case cpuUsagePercent = "cpu_usage_percent"
        case memoryUsageMb = "memory_usage_mb"
        case memoryTotalMb = "memory_total_mb"
        case diskUsageGb = "disk_usage_gb"
        case diskTotalGb = "disk_total_gb"
        case networkRxMb = "network_rx_mb"
        case networkTxMb = "network_tx_mb"
        case uptimeSeconds = "uptime_seconds"
    }
}

public struct RuntimeMetrics: Codable, Sendable {
    public let activeSessions: Int
    public let totalSessions: Int
    public let activeTasks: Int
    public let completedTasks: Int
    public let failedTasks: Int
    public let toolExecutions: Int
    public let agentInvocations: Int
    public let errorsLastHour: Int
    
    private enum CodingKeys: String, CodingKey {
        case activeSessions = "active_sessions"
        case totalSessions = "total_sessions"
        case activeTasks = "active_tasks"
        case completedTasks = "completed_tasks"
        case failedTasks = "failed_tasks"
        case toolExecutions = "tool_executions"
        case agentInvocations = "agent_invocations"
        case errorsLastHour = "errors_last_hour"
    }
}

public struct DatabaseMetrics: Codable, Sendable {
    public let connectionsActive: Int
    public let connectionsTotal: Int
    public let queriesExecuted: Int
    public let queriesFailed: Int
    public let avgQueryTimeMs: Double
    public let databaseSizeMb: Double
    
    private enum CodingKeys: String, CodingKey {
        case connectionsActive = "connections_active"
        case connectionsTotal = "connections_total"
        case queriesExecuted = "queries_executed"
        case queriesFailed = "queries_failed"
        case avgQueryTimeMs = "avg_query_time_ms"
        case databaseSizeMb = "database_size_mb"
    }
}

public struct ContainerMetrics: Codable, Sendable {
    public let containersRunning: Int
    public let containersTotal: Int
    public let containersCreated: Int
    public let containersStopped: Int
    public let containersFailed: Int
    public let totalCpuUsagePercent: Double
    public let totalMemoryUsageMb: Double
    
    private enum CodingKeys: String, CodingKey {
        case containersRunning = "containers_running"
        case containersTotal = "containers_total"
        case containersCreated = "containers_created"
        case containersStopped = "containers_stopped"
        case containersFailed = "containers_failed"
        case totalCpuUsagePercent = "total_cpu_usage_percent"
        case totalMemoryUsageMb = "total_memory_usage_mb"
    }
}

public struct LLMMetrics: Codable, Sendable {
    public let requestsTotal: Int
    public let requestsSuccessful: Int
    public let requestsFailed: Int
    public let tokensUsed: Int
    public let tokensCached: Int
    public let avgResponseTimeMs: Double
    public let costEstimateUsd: Double
    
    private enum CodingKeys: String, CodingKey {
        case requestsTotal = "requests_total"
        case requestsSuccessful = "requests_successful"
        case requestsFailed = "requests_failed"
        case tokensUsed = "tokens_used"
        case tokensCached = "tokens_cached"
        case avgResponseTimeMs = "avg_response_time_ms"
        case costEstimateUsd = "cost_estimate_usd"
    }
}

public struct HealthResponse: Codable, Sendable {
    public let data: HealthData
}

public struct HealthData: Codable, Sendable {
    public let status: String
    public let timestamp: String
    public let components: [String: ComponentHealth]
    public let version: String
    public let uptimeSeconds: Int
    
    private enum CodingKeys: String, CodingKey {
        case status, timestamp, components, version
        case uptimeSeconds = "uptime_seconds"
    }
    
    public var timestampDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp)
    }
}

public struct ComponentHealth: Codable, Sendable {
    public let status: String
    public let message: String
    public let lastCheck: String
    public let responseTimeMs: Double?
    
    private enum CodingKeys: String, CodingKey {
        case status, message
        case lastCheck = "last_check"
        case responseTimeMs = "response_time_ms"
    }
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