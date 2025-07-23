import Foundation

/// Defines all REST API endpoints for the Aria platform
public enum APIEndpoints {
    
    // MARK: - Sessions
    
    /// POST /api/v1/sessions - Create a new session
    public static let createSession = "/sessions"
    
    /// GET /api/v1/sessions/{session_id} - Get session details
    public static func getSession(_ sessionId: String) -> String {
        "/sessions/\(sessionId)"
    }
    
    /// POST /api/v1/sessions/{session_id}/turns - Execute a turn (SSE streaming)
    public static func executeTurn(_ sessionId: String) -> String {
        "/sessions/\(sessionId)/turns"
    }
    
    // MARK: - Tasks
    
    /// POST /api/v1/tasks - Launch a new task
    public static let createTask = "/tasks"
    
    /// GET /api/v1/sessions - List sessions (with query params) - displayed as Task View
    public static let listTasks = "/sessions"
    
    /// GET /api/v1/tasks/{task_id} - Get task details
    public static func getTask(_ taskId: String) -> String {
        "/tasks/\(taskId)"
    }
    
    /// GET /api/v1/tasks/{task_id}/output - Stream task output (SSE streaming)
    public static func taskOutput(_ taskId: String) -> String {
        "/tasks/\(taskId)/output"
    }
    
    /// POST /api/v1/tasks/{task_id}/cancel - Cancel a task
    public static func cancelTask(_ taskId: String) -> String {
        "/tasks/\(taskId)/cancel"
    }
    
    // MARK: - Notifications
    
    /// GET /api/v1/notifications/stream - Stream notifications (SSE streaming)
    public static let notificationsStream = "/notifications/stream"
    
    // MARK: - Authentication
    
    /// POST /api/auth/link-magic - Link magic number to user account
    public static let linkMagic = "/auth/link-magic"
    
    /// GET /api/auth/magic-status - Check magic number link status
    public static let magicStatus = "/auth/magic-status"
    
    /// POST /api/auth/refresh - Refresh authentication tokens
    public static let refreshToken = "/auth/refresh"
    
    // MARK: - Bundles
    
    /// POST /api/v1/bundles/upload - Upload a bundle
    public static let uploadBundle = "/bundles/upload"
    
    // MARK: - Tool & Agent Registry
    
    /// GET /api/v1/registry/tools - List available tools
    public static let toolsRegistry = "/registry/tools"
    
    /// GET /api/v1/registry/agents - List available agents
    public static let agentsRegistry = "/registry/agents"
    
    /// GET /api/v1/registry/tools/{name} - Get tool details
    public static func toolDetails(_ name: String) -> String {
        "/registry/tools/\(name)"
    }
    
    // MARK: - Model Management
    
    /// GET /api/v1/models/providers - List model providers
    public static let modelProviders = "/models/providers"
    
    /// GET /api/v1/models/providers/{provider}/models - List provider models
    public static func providerModels(_ provider: String) -> String {
        "/models/providers/\(provider)/models"
    }
    
    /// POST /api/v1/models/select - Select model
    public static let selectModel = "/models/select"
    
    /// POST /api/v1/models/test - Test model
    public static let testModel = "/models/test"
    
    /// GET /api/v1/models/usage - Get usage statistics
    public static let modelUsage = "/models/usage"
    
    // MARK: - Observability
    
    /// GET /api/v1/logs/stream - Stream logs (SSE)
    public static let logsStream = "/logs/stream"
    
    /// GET /api/v1/logs/recent - Get recent logs
    public static let logsRecent = "/logs/recent"
    
    /// GET /api/v1/metrics - Get metrics
    public static let metrics = "/metrics"
    
    /// GET /api/v1/health - Health check
    public static let health = "/health"
    
    // MARK: - Query Parameters
    
    public struct QueryParams {
        public static func listTasks(
            limit: Int? = nil,
            offset: Int? = nil
        ) -> [URLQueryItem] {
            var items: [URLQueryItem] = []
            
            if let limit = limit {
                items.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            
            if let offset = offset {
                items.append(URLQueryItem(name: "offset", value: String(offset)))
            }
            
            return items
        }
        
        public static func taskOutput(follow: Bool) -> [URLQueryItem] {
            [URLQueryItem(name: "follow", value: String(follow))]
        }
        
        public static func magicStatus(magic: String) -> [URLQueryItem] {
            [URLQueryItem(name: "magic", value: magic)]
        }
        
        public static func toolsRegistry(
            search: String? = nil,
            category: String? = nil,
            scope: String? = nil
        ) -> [URLQueryItem] {
            var items: [URLQueryItem] = []
            
            if let search = search {
                items.append(URLQueryItem(name: "search", value: search))
            }
            
            if let category = category {
                items.append(URLQueryItem(name: "category", value: category))
            }
            
            if let scope = scope {
                items.append(URLQueryItem(name: "scope", value: scope))
            }
            
            return items
        }
        
        public static func agentsRegistry(search: String? = nil) -> [URLQueryItem] {
            var items: [URLQueryItem] = []
            
            if let search = search {
                items.append(URLQueryItem(name: "search", value: search))
            }
            
            return items
        }
        
        public static func modelUsage(period: String) -> [URLQueryItem] {
            [URLQueryItem(name: "period", value: period)]
        }
        
        public static func logsRecent(
            limit: Int? = nil,
            level: String? = nil,
            component: String? = nil,
            sessionId: String? = nil,
            since: String? = nil,
            until: String? = nil
        ) -> [URLQueryItem] {
            var items: [URLQueryItem] = []
            
            if let limit = limit {
                items.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            
            if let level = level {
                items.append(URLQueryItem(name: "level", value: level))
            }
            
            if let component = component {
                items.append(URLQueryItem(name: "component", value: component))
            }
            
            if let sessionId = sessionId {
                items.append(URLQueryItem(name: "session_id", value: sessionId))
            }
            
            if let since = since {
                items.append(URLQueryItem(name: "since", value: since))
            }
            
            if let until = until {
                items.append(URLQueryItem(name: "until", value: until))
            }
            
            return items
        }
        
        public static func logsStream(
            filterComponents: [String]? = nil,
            sessionId: String? = nil
        ) -> [URLQueryItem] {
            var items: [URLQueryItem] = []
            
            if let components = filterComponents {
                for component in components {
                    items.append(URLQueryItem(name: "filter[components][]", value: component))
                }
            }
            
            if let sessionId = sessionId {
                items.append(URLQueryItem(name: "filter[session_id]", value: sessionId))
            }
            
            return items
        }
    }
}