import Foundation
import SwiftUI

// MARK: - Step Types
enum StepType {
    case userMessage
    case thought
    case tool
    case response
}

// MARK: - Execution Context Models
struct ThinkingStep: Codable, Identifiable, Sendable {
    let id: String
    let step: Int
    let type: String
    let content: String
    let confidence: Double?
    let timestamp: Date?
    
    public init(id: String = UUID().uuidString, step: Int, type: String, content: String, confidence: Double? = nil, timestamp: Date? = nil) {
        self.id = id
        self.step = step
        self.type = type
        self.content = content
        self.confidence = confidence
        self.timestamp = timestamp
    }
}

struct ExecutionContext: Codable, Sendable {
    let duration_ms: Int?
    let memory_used: String?
    let tokens_consumed: Int?
    let cpu_percent: Double?
    let execution_time_ms: Int?
    let inputValidation: String?
    
    public init(duration_ms: Int? = nil, memory_used: String? = nil, tokens_consumed: Int? = nil, cpu_percent: Double? = nil, execution_time_ms: Int? = nil, inputValidation: String? = nil) {
        self.duration_ms = duration_ms
        self.memory_used = memory_used
        self.tokens_consumed = tokens_consumed
        self.cpu_percent = cpu_percent
        self.execution_time_ms = execution_time_ms
        self.inputValidation = inputValidation
    }
}

enum StepStatus: String {
    case active
    case completed
    case failed
}

struct EnhancedStep: Identifiable, Sendable {
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
    
    // Rich SSE metadata for details pane (using Data for Sendable compliance)
    var detailedResultsData: Data?
    var thinkingSteps: [ThinkingStep]?
    var executionContext: ExecutionContext?
    var rawResultJSONData: Data?
    
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
    
    // Auto-scroll state management
    @Published var shouldAutoScroll = true
    @Published var isUserScrolling = false
    var scrollDebounceTimer: Timer?
    
    // Memory management configuration
    private let maxMessagesInMemory = AppConfiguration.Performance.maxMessagesInMemory
    private let messageCleanupThreshold = AppConfiguration.Performance.messageCleanupThreshold
    private var lastMemoryPressureCheck = Date()
    
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
    
    // Fallback menu items when registry loading fails
    private let fallbackToolMenuItems: [MenuItem] = [
        MenuItem(id: "loading-tools", name: "Loading Tools...", category: .tools, disabled: true),
        MenuItem(id: "loading-agents", name: "Loading Agents...", category: .agents, disabled: true)
    ]
    
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
        
        // Start with fallback items to prevent empty menu
        self.toolMenuItems = fallbackToolMenuItems
        
        // Load dynamic tool menu items
        loadToolMenuItems()
    }
    
    private func loadToolMenuItems() {
        Task {
            do {
                // Load tools and agents from registry
                async let toolsTask: Void = registryService.loadTools()
                async let agentsTask: Void = registryService.loadAgents()
                
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
                    
                    // Only update if we got items, otherwise keep fallback
                    if !menuItems.isEmpty {
                        self.toolMenuItems = menuItems
                        print("GlassmorphicChatbarState: Loaded \(menuItems.count) dynamic tool menu items")
                    } else {
                        // Create a "no items available" state
                        self.toolMenuItems = [
                            MenuItem(id: "no-tools", name: "No Tools Available", category: .tools, disabled: true),
                            MenuItem(id: "no-agents", name: "No Agents Available", category: .agents, disabled: true)
                        ]
                        print("GlassmorphicChatbarState: No tool menu items loaded, showing empty state")
                    }
                }
                
            } catch {
                print("GlassmorphicChatbarState: Error loading tool menu items: \(error)")
                await MainActor.run {
                    // Show error state
                    self.toolMenuItems = [
                        MenuItem(id: "error-tools", name: "Failed to Load Tools", category: .tools, disabled: true),
                        MenuItem(id: "retry-tools", name: "Retry Loading", category: .tools)
                    ]
                }
            }
        }
    }
    
    public func refreshToolMenuItems() {
        // Reset to loading state
        self.toolMenuItems = fallbackToolMenuItems
        loadToolMenuItems()
    }
    
    public func handleToolMenuItemSelection(_ item: MenuItem) {
        if item.id == "retry-tools" {
            refreshToolMenuItems()
        }
        // Handle other menu item selections here
    }
    
    // MARK: - Production-Ready Memory Management
    
    /// Adds a new step and manages memory automatically
    public func addStep(_ step: EnhancedStep) {
        aiSteps.append(step)
        
        // Check for memory cleanup every 10 messages or every 30 seconds
        if aiSteps.count % 10 == 0 || Date().timeIntervalSince(lastMemoryPressureCheck) > 30 {
            checkAndCleanupMemory()
        }
    }
    
    /// Intelligently cleans up old messages while preserving important ones
    private func checkAndCleanupMemory() {
        lastMemoryPressureCheck = Date()
        
        guard aiSteps.count > messageCleanupThreshold else { return }
        
        let stepsToKeep = selectImportantSteps()
        
        // Keep the most recent messages and important historical ones
        let recentSteps = Array(aiSteps.suffix(maxMessagesInMemory / 2))
        let combinedSteps = Array((stepsToKeep + recentSteps).suffix(maxMessagesInMemory))
        
        // Only update if we're actually reducing memory usage
        if combinedSteps.count < aiSteps.count {
            aiSteps = combinedSteps
            print("🧹 Memory cleanup: Reduced from \(aiSteps.count) to \(combinedSteps.count) messages")
        }
    }
    
    /// Selects important steps that should be preserved during cleanup
    private func selectImportantSteps() -> [EnhancedStep] {
        let importantSteps = aiSteps.filter { step in
            // Keep user messages (conversation context)
            step.type == .userMessage ||
            // Keep final responses (key outcomes)
            (step.type == .response && step.metadata?.isFinal == true) ||
            // Keep error messages (debugging context)
            step.status == .failed ||
            // Keep highlighted/selected messages
            step.id == activeHighlightId
        }
        
        // Limit important steps to prevent unbounded growth
        return Array(importantSteps.suffix(maxMessagesInMemory / 2))
    }
    
    /// Force cleanup for testing or low memory situations
    public func forceMemoryCleanup() {
        if aiSteps.count > maxMessagesInMemory {
            aiSteps = Array(aiSteps.suffix(maxMessagesInMemory))
            print("🚨 Force memory cleanup: Reduced to \(aiSteps.count) messages")
        }
    }
}