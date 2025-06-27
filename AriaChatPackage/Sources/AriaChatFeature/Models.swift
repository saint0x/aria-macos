import Foundation
import SwiftUI

// MARK: - Step Types
enum StepType {
    case userMessage
    case thought
    case tool
    case response
}

enum StepStatus: String {
    case active
    case completed
    case failed
}

struct EnhancedStep: Identifiable {
    let id: String
    let type: StepType
    let text: String
    var status: StepStatus = .active
    let timestamp: Date = Date()
    var toolName: String?
    var isIndented: Bool = false
}

// MARK: - Menu Items
struct MenuItem: Identifiable {
    let id: String
    let name: String
    var action: (() -> Void)?
    var separator: String?
    var disabled: Bool = false
}

// MARK: - Task
public enum TaskStatus: String {
    case completed = "Completed"
    case running = "Running"
    case inProgress = "In Progress"
    case paused = "Paused"
    case failed = "Failed"
    case pending = "Pending"
}

public struct AriaTask: Identifiable {
    public let id: String
    public let title: String
    public let detailIdentifier: String
    public let status: TaskStatus
    public let timestamp: Date
}

// MARK: - View States
@MainActor
class GlassmorphicChatbarState: ObservableObject {
    @Published var isOpen = true
    @Published var expanded = false
    @Published var inputValue = ""
    @Published var isToolMenuOpen = false
    @Published var isViewMenuOpen = false
    @Published var aiSteps: [EnhancedStep] = []
    @Published var isProcessing = false
    @Published var processingComplete = false
    @Published var selectedItemForDetail: EnhancedStep?
    @Published var showAiChatFlow = false
    @Published var activeHighlightId: String?
    @Published var activeTool: MenuItem?
    @Published var activeView: MenuItem
    @Published var blurIntensity: CGFloat = 24
    @Published var showToolUploadSuccess = false
    @Published var chatbarSize: CGSize = .zero
    
    // Service managers
    let sessionManager = SessionManager.shared
    let chatService = ChatService.shared
    let taskManager = TaskManager.shared
    
    let mockTasks: [AriaTask] = [
        AriaTask(id: "1", title: "Implement authentication", detailIdentifier: "AUTH-001", status: .inProgress, timestamp: Date()),
        AriaTask(id: "2", title: "Database optimization", detailIdentifier: "DB-002", status: .pending, timestamp: Date()),
        AriaTask(id: "3", title: "API integration", detailIdentifier: "API-003", status: .completed, timestamp: Date())
    ]
    
    let toolMenuItems: [MenuItem] = [
        MenuItem(id: "analyzerTool", name: "Analyzer Tool"),
        MenuItem(id: "devConsoleTool", name: "Developer Console"),
        MenuItem(id: "dataVizTool", name: "Data Visualizer"),
        MenuItem(id: "apiExplorerTool", name: "API Explorer"),
        MenuItem(id: "workflowTool", name: "Workflow Automator"),
        MenuItem(id: "contentGenTool", name: "Content Generator"),
        MenuItem(id: "securityScanTool", name: "Security Scanner"),
        MenuItem(id: "collabHubTool", name: "Collaboration Hub")
    ]
    
    let viewMenuItems: [MenuItem]
    
    init() {
        let items = [
            MenuItem(id: "taskListView", name: "Task View"),
            MenuItem(id: "loggingView", name: "Logging"),
            MenuItem(id: "graphView", name: "Graph View", disabled: true),
            MenuItem(id: "billingView", name: "Billing", separator: "before"),
            MenuItem(id: "settingsView", name: "Settings")
        ]
        self.viewMenuItems = items
        self.activeView = items[0]
    }
}