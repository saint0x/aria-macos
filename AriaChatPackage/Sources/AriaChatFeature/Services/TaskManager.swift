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
    
    private init() {}
    
    /// Lists tasks with optional filtering
    public func listTasks(
        sessionId: String? = nil,
        agentId: String? = nil,
        statusFilter: [String]? = nil,
        refresh: Bool = false
    ) async throws {
        if refresh {
            tasks = []
            nextPageToken = nil
        }
        
        isLoadingTasks = true
        taskError = nil
        
        defer {
            isLoadingTasks = false
        }
        
        print("TaskManager: Starting listTasks")
        
        do {
            print("TaskManager: Building query parameters...")
            
            let queryItems = APIEndpoints.QueryParams.listTasks(
                sessionId: sessionId,
                filterByStatus: statusFilter,
                pageSize: pageSize,
                pageToken: refresh ? nil : nextPageToken
            )
            
            print("TaskManager: Sending GET request to list tasks...")
            let response = try await apiClient.get(
                APIEndpoints.listTasks,
                queryItems: queryItems,
                type: ListTasksResponse.self
            )
            
            print("TaskManager: Got response with \(response.tasks.count) tasks")
            
            if refresh {
                self.tasks = response.tasks
            } else {
                self.tasks.append(contentsOf: response.tasks)
            }
            
            self.nextPageToken = response.nextPageToken?.isEmpty ?? true ? nil : response.nextPageToken
            self.hasMoreTasks = response.nextPageToken != nil && !response.nextPageToken!.isEmpty
            
        } catch {
            print("TaskManager: Error listing tasks: \(error)")
            self.taskError = error
            throw error
        }
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