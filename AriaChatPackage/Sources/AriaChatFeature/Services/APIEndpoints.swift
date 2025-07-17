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
    
    /// GET /api/v1/tasks - List tasks (with query params)
    public static let listTasks = "/tasks"
    
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
    
    // MARK: - Query Parameters
    
    public struct QueryParams {
        public static func listTasks(
            sessionId: String? = nil,
            filterByStatus: [String]? = nil,
            pageSize: Int? = nil,
            pageToken: String? = nil
        ) -> [URLQueryItem] {
            var items: [URLQueryItem] = []
            
            if let sessionId = sessionId {
                items.append(URLQueryItem(name: "session_id", value: sessionId))
            }
            
            if let statuses = filterByStatus {
                for status in statuses {
                    items.append(URLQueryItem(name: "filter_by_status[]", value: status))
                }
            }
            
            if let pageSize = pageSize {
                items.append(URLQueryItem(name: "page_size", value: String(pageSize)))
            }
            
            if let pageToken = pageToken {
                items.append(URLQueryItem(name: "page_token", value: pageToken))
            }
            
            return items
        }
        
        public static func taskOutput(follow: Bool) -> [URLQueryItem] {
            [URLQueryItem(name: "follow", value: String(follow))]
        }
        
        public static func magicStatus(magic: String) -> [URLQueryItem] {
            [URLQueryItem(name: "magic", value: magic)]
        }
    }
}