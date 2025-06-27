import Foundation
import SwiftUI
import Combine
import GRPC

/// Manages tasks and interactions with the AriaRuntime service
@MainActor
public class TaskManager: ObservableObject {
    public static let shared = TaskManager()
    
    @Published public private(set) var tasks: [Aria_Task] = []
    @Published public private(set) var isLoadingTasks = false
    @Published public private(set) var taskError: Error?
    @Published public private(set) var nextPageToken: String?
    @Published public private(set) var hasMoreTasks = false
    
    private let client = AriaRuntimeClient.shared
    private let pageSize: Int32 = 20
    
    private init() {}
    
    /// Lists tasks with optional filtering
    public func listTasks(
        sessionId: String? = nil,
        agentId: String? = nil,
        statusFilter: Aria_TaskStatus? = nil,
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
            print("TaskManager: Creating task service client...")
            let taskService = try await client.makeTaskServiceClient()
            print("TaskManager: Got task service client")
            
            var request = Aria_ListTasksRequest()
            request.pageSize = pageSize
            
            if let sessionId = sessionId {
                request.sessionID = sessionId
            }
            
            // Note: agentID field doesn't exist in proto
            
            if let statusFilter = statusFilter {
                request.filterByStatus = [statusFilter]
            }
            
            if let token = nextPageToken, !refresh {
                request.pageToken = token
            }
            
            print("TaskManager: Sending ListTasks request...")
            let call = taskService.listTasks(request)
            print("TaskManager: Waiting for response...")
            let response = try await call.response.get()
            print("TaskManager: Got response with \(response.tasks.count) tasks")
            
            if refresh {
                self.tasks = response.tasks
            } else {
                self.tasks.append(contentsOf: response.tasks)
            }
            
            self.nextPageToken = response.nextPageToken.isEmpty ? nil : response.nextPageToken
            self.hasMoreTasks = !response.nextPageToken.isEmpty
            
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
    
    /// Get a specific task by ID
    public func getTask(by id: String) -> Aria_Task? {
        return tasks.first { $0.id == id }
    }
    
    /// Convert proto task status to our TaskStatus enum
    public func mapTaskStatus(_ protoStatus: Aria_TaskStatus) -> TaskStatus {
        switch protoStatus {
        case .running:
            return .running
        case .pending:
            return .pending
        case .completed:
            return .completed
        case .failed:
            return .failed
        case .cancelled:
            return .failed
        case .timeout:
            return .failed
        case .UNRECOGNIZED:
            return .pending
        default:
            return .pending
        }
    }
    
    /// Convert our TaskStatus to proto task status
    public func mapToProtoStatus(_ status: TaskStatus) -> Aria_TaskStatus {
        switch status {
        case .running:
            return .running
        case .paused:
            return .pending
        case .completed:
            return .completed
        case .failed:
            return .failed
        case .pending:
            return .pending
        case .inProgress:
            return .running
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