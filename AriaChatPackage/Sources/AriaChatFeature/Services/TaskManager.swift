import Foundation
import SwiftUI
import Combine

/// Manages tasks and interactions with the Task service
@MainActor
public class TaskManager: ObservableObject {
    public static let shared = TaskManager()
    
    @Published public private(set) var tasks: [TaskResponse] = []
    @Published public private(set) var isLoadingTasks = false
    @Published public private(set) var taskError: Error?
    @Published public private(set) var nextPageToken: String?
    @Published public private(set) var hasMoreTasks = false
    
    private let apiClient = RESTAPIClient.shared
    private let pageSize = 20
    private var currentOffset = 0
    
    private init() {}
    
    // NOTE: TaskManager is now reserved for actual task operations when backend supports them
    // Session management has been moved to ChatSessionManager for proper separation of concerns
    
    /// Lists actual tasks
    public func listTasks(
        sessionId: String? = nil,
        agentId: String? = nil,
        statusFilter: [String]? = nil,
        refresh: Bool = false
    ) async throws {
        if refresh {
            tasks = []
            nextPageToken = nil
            currentOffset = 0
        }
        
        isLoadingTasks = true
        taskError = nil
        
        defer {
            isLoadingTasks = false
        }
        
        print("TaskManager: Loading tasks...")
        
        // Simulate loading tasks - in a real implementation this would call the tasks API
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        
        // Mock tasks for demonstration
        let mockTasks = [
            TaskResponse(
                id: "task_1",
                type: "analysis", 
                status: "completed",
                createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
                updatedAt: Date().addingTimeInterval(-1800), // 30 min ago
                sessionId: nil,
                payload: TaskPayload(command: "analyze_data", args: ["dataset": AnyCodable("user_metrics.csv")]),
                result: TaskResult(output: "Analysis complete", error: nil, exitCode: 0)
            ),
            TaskResponse(
                id: "task_2", 
                type: "processing",
                status: "running",
                createdAt: Date().addingTimeInterval(-1800), // 30 min ago
                updatedAt: Date().addingTimeInterval(-300), // 5 min ago
                sessionId: nil,
                payload: TaskPayload(command: "process_images", args: ["batch_size": AnyCodable(50)]),
                result: nil
            )
        ]
        
        if refresh {
            self.tasks = mockTasks
        } else {
            self.tasks.append(contentsOf: mockTasks)
        }
        
        hasMoreTasks = false // No pagination for mock data
        print("TaskManager: Loaded \(mockTasks.count) tasks")
    }
    
    /// Load more tasks if available
    public func loadMoreTasks() async throws {
        guard hasMoreTasks, !isLoadingTasks else { return }
        try await listTasks(refresh: false)
    }
    
    /// Get a specific task by ID from cache
    public func getTask(by id: String) -> TaskResponse? {
        return tasks.first { $0.id == id }
    }
    
    /// Fetch a specific task by ID from server
    public func fetchTask(by id: String) async throws -> TaskResponse {
        do {
            print("TaskManager: Fetching task \(id)...")
            
            let response = try await apiClient.get(
                APIEndpoints.getTask(id),
                type: TaskResponse.self
            )
            
            print("TaskManager: Got task details")
            
            // Update cache if we have this task
            if let index = tasks.firstIndex(where: { $0.id == id }) {
                tasks[index] = response
            }
            
            return response
        } catch {
            print("TaskManager: Error fetching task: \(error)")
            throw error
        }
    }
    
    /// Create a new task
    public func createTask(
        type: String,
        command: String? = nil,
        args: [String: AnyCodable]? = nil,
        sessionId: String? = nil
    ) async throws -> TaskResponse {
        do {
            print("TaskManager: Creating task of type \(type)...")
            
            let payload = TaskPayload(command: command, args: args)
            let request = CreateTaskRequest(
                type: type,
                payload: payload,
                sessionId: sessionId
            )
            
            let response = try await apiClient.post(
                APIEndpoints.createTask,
                body: request,
                type: TaskResponse.self
            )
            
            print("TaskManager: Created task with ID: \(response.id)")
            
            // Add to local cache
            tasks.insert(response, at: 0)
            
            return response
        } catch {
            print("TaskManager: Error creating task: \(error)")
            throw error
        }
    }
    
    /// Cancel a task
    public func cancelTask(_ taskId: String) async throws {
        do {
            print("TaskManager: Cancelling task \(taskId)...")
            
            try await apiClient.post(APIEndpoints.cancelTask(taskId))
            
            print("TaskManager: Task cancelled")
            
            // Update local cache
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                tasks[index].status = "cancelled"
            }
        } catch {
            print("TaskManager: Error cancelling task: \(error)")
            throw error
        }
    }
    
    /// Convert API task status string to our TaskStatus enum
    public func mapTaskStatus(_ status: String) -> TaskStatus {
        switch status.lowercased() {
        case "running":
            return .running
        case "pending":
            return .pending
        case "completed":
            return .completed
        case "failed":
            return .failed
        case "cancelled":
            return .failed
        case "timeout":
            return .failed
        default:
            return .pending
        }
    }
    
    /// Convert our TaskStatus to API status string
    public func mapToAPIStatus(_ status: TaskStatus) -> String {
        switch status {
        case .running:
            return "running"
        case .paused:
            return "pending"
        case .completed:
            return "completed"
        case .failed:
            return "failed"
        case .pending:
            return "pending"
        case .inProgress:
            return "running"
        }
    }
    
    /// Clear all tasks
    public func clearTasks() {
        tasks = []
        nextPageToken = nil
        hasMoreTasks = false
        taskError = nil
    }
}