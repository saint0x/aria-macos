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
    var metadata: MessageMetadata?
    var toolParameters: [String: String]?
    var toolResult: String?
    var errorMessage: String?
    
    /// Computed property to determine if this step should be visible in the main chat
    var isVisibleInMainChat: Bool {
        MessageFilterUtils.isVisibleInMainChat(self)
    }
}

// MARK: - Menu Items
enum MenuCategory: String, CaseIterable {
    case agents = "agents"
    case tools = "tools"
    case teams = "teams"
    case pipelines = "pipelines"
    
    var displayName: String {
        switch self {
        case .agents: return "Agent"
        case .tools: return "Tool"
        case .teams: return "Team"
        case .pipelines: return "Pipeline"
        }
    }
    
    var color: Color {
        switch self {
        case .agents: return Color.blue
        case .tools: return Color.green
        case .teams: return Color.purple
        case .pipelines: return Color.orange
        }
    }
}

struct MenuItem: Identifiable {
    let id: String
    let name: String
    let category: MenuCategory?
    var action: (() -> Void)?
    var separator: String?
    var disabled: Bool = false
    
    var color: Color {
        return category?.color ?? Color.clear
    }
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
    
    @Published var toolMenuItems: [MenuItem] = []
    
    // Registry service for dynamic loading
    private let registryService = RegistryService.shared
    
    let viewMenuItems: [MenuItem]
    
    init() {
        let items = [
            MenuItem(id: "taskListView", name: "Task View", category: nil),
            MenuItem(id: "loggingView", name: "Logging", category: nil),
            MenuItem(id: "graphView", name: "Graph View", category: nil, disabled: true),
            MenuItem(id: "billingView", name: "Billing", category: nil, separator: "before"),
            MenuItem(id: "settingsView", name: "Settings", category: nil)
        ]
        self.viewMenuItems = items
        self.activeView = items[0]
        
        // Load dynamic tool menu items
        loadToolMenuItems()
    }
    
    private func loadToolMenuItems() {
        Task {
            do {
                // Load tools and agents from registry
                async let toolsTask = registryService.loadTools()
                async let agentsTask = registryService.loadAgents()
                
                try await toolsTask
                try await agentsTask
                
                await MainActor.run {
                    var menuItems: [MenuItem] = []
                    
                    // Add agents
                    for agent in registryService.getAvailableAgents() {
                        menuItems.append(MenuItem(
                            id: agent.id,
                            name: agent.name,
                            category: .agents
                        ))
                    }
                    
                    // Add tools
                    for tool in registryService.getAvailableTools() {
                        menuItems.append(MenuItem(
                            id: tool.id,
                            name: tool.name,
                            category: .tools
                        ))
                    }
                    
                    // TODO: Add teams and pipelines when available from backend
                    
                    self.toolMenuItems = menuItems
                    print("GlassmorphicChatbarState: Loaded \(menuItems.count) dynamic tool menu items")
                }
                
            } catch {
                print("GlassmorphicChatbarState: Error loading tool menu items: \(error)")
                // Fall back to empty array or keep existing items
            }
        }
    }
    
    public func refreshToolMenuItems() {
        loadToolMenuItems()
    }
}