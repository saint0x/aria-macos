import SwiftUI
import Combine

// Preference key to communicate size changes
public struct ChatbarSizePreferenceKey: PreferenceKey {
    public static let defaultValue: CGSize? = nil
    
    public static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        value = nextValue() ?? value
    }
}

public struct GlassmorphicChatbar: View {
    public init() {}
    
    @StateObject private var state = GlassmorphicChatbarState()
    @StateObject private var blurSettings = BlurSettings.shared
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isInputFocused: Bool
    
    private let maxWidth: CGFloat = 512 // max-w-lg equivalent (32rem = 512px)
    private let expandedHeight: CGFloat = 450
    
    public var body: some View {
        ZStack {
            // Main content stack
            VStack(spacing: 0) {
                // Main chatbar
                mainChatbar
                    .frame(maxWidth: maxWidth)
                
                // Dropdowns positioned below chatbar with overlay to prevent layout shift
                Color.clear
                    .frame(height: 0)
                    .frame(maxWidth: maxWidth)
                    .overlay(alignment: .top) {
                        ZStack(alignment: .top) {
                            // Tool dropdown - aligned to leading edge
                            if state.isToolMenuOpen {
                                HStack {
                                    DropdownMenuView(items: state.toolMenuItems, onSelect: handleToolSelect, isOpen: $state.isToolMenuOpen)
                                        .frame(width: 180)
                                        .padding(.leading, 12) // Match footer button padding
                                    Spacer()
                                }
                                .frame(maxWidth: maxWidth)
                                .padding(.top, 16) // 16pt gap below chatbar
                                .zIndex(9999)
                            }
                            
                            // View dropdown - aligned to trailing edge
                            if state.isViewMenuOpen {
                                HStack {
                                    Spacer()
                                    DropdownMenuView(items: state.viewMenuItems, onSelect: handleViewSelect, isOpen: $state.isViewMenuOpen)
                                        .frame(width: 180)
                                        .padding(.trailing, 12) // Match footer button padding
                                }
                                .frame(maxWidth: maxWidth)
                                .padding(.top, 16) // 16pt gap below chatbar
                                .zIndex(9999)
                            }
                        }
                    }
                
                // Tool upload success display (when not expanded)
                if !state.expanded && state.showToolUploadSuccess {
                    ToolUploadSuccessDisplay(message: "Custom tool uploaded successfully!")
                        .padding(.top, 16)
                        .frame(maxWidth: maxWidth)
                        .expandIn(isVisible: true)
                }
            }
            
            // Detail pane absolutely positioned to the right
            if let selectedItem = state.selectedItemForDetail {
                StepDetailPane(
                    step: selectedItem,
                    onClose: { state.selectedItemForDetail = nil },
                    tasks: state.mockTasks
                )
                .offset(x: (maxWidth / 2) + (320 / 2) + 16) // Fixed position: half chatbar + half pane + gap
                .slideInFromRight(isVisible: true)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
            
            // Invisible background for clicks outside dropdowns
            if state.isToolMenuOpen || state.isViewMenuOpen {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        state.isToolMenuOpen = false
                        state.isViewMenuOpen = false
                    }
                    .frame(width: 2000, height: 1200) // Match canvas size
                    .zIndex(1)
            }
        }
        .onAppear {
            // Start collapsed like the React component
            state.expanded = false
            state.showAiChatFlow = false
        }
        .onKeyPress(.escape) {
            // ESC key handling: close dropdowns first, then detail pane, then collapse chatbar
            if state.isToolMenuOpen {
                state.isToolMenuOpen = false
                return .handled
            } else if state.isViewMenuOpen {
                state.isViewMenuOpen = false
                return .handled
            } else if state.selectedItemForDetail != nil {
                state.selectedItemForDetail = nil
                return .handled
            } else if state.expanded {
                state.expanded = false
                return .handled
            }
            return .ignored
        }
    }
    
    private var mainChatbar: some View {
        VStack(spacing: 0) {
            // Content
            VStack(spacing: 0) {
                // Input section
                inputSection
                
                // Expanded content
                if state.expanded {
                    expandedContent
                        .transition(.asymmetric(
                            insertion: .offset(y: 10).combined(with: .opacity),
                            removal: .offset(y: 8).combined(with: .opacity)
                        ))
                }
                
                // Footer controls
                footerControls
            }
        }
        .frame(height: state.expanded ? expandedHeight : nil)
        .glassmorphic(cornerRadius: 22)
        .appleShadow()
        .overlay(
            // Top gradient highlight - 1pt line as per SWIFT2.md
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [.clear, Color.white.opacity(0.3), .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
                Spacer()
            }
        )
        .overlay(
            // Bottom gradient lowlight - 1pt line as per SWIFT2.md
            VStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(colors: [.clear, Color.black.opacity(0.05), .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
            }
        )
        .animation(.easeInOut(duration: 0.3), value: state.expanded)
    }
    
    private var inputSection: some View {
        HStack(spacing: 0) {
            // Input field with inner shadow effect matching React component
            HStack(spacing: 8) {
                TextField(currentPlaceholder, text: $state.inputValue)
                    .textFieldStyle(.plain)
                    .font(.textSM)
                    .foregroundColor(Color.textPrimary(for: colorScheme))
                    .focused($isInputFocused)
                    .disabled(state.isProcessing)
                    .onSubmit {
                        handleSubmit()
                    }
                
                if !state.inputValue.isEmpty && !state.isProcessing {
                    InteractiveButton(action: handleSubmit) {
                        Image(systemName: "paperplane.fill")
                            .font(.textSM)
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                            .padding(4)
                    }
                }
            }
            .padding(.horizontal, 12) // px-3 = 12px
            .padding(.vertical, 10) // py-2.5 = 10px
            .background(
                RoundedRectangle(cornerRadius: 16) // rounded-xl = var(--radius) + 4px = 12 + 4 = 16pt
                    .fill(Color.inputBackground(for: colorScheme))
            )
            .innerShadow(cornerRadius: 16)
        }
        .padding(.horizontal, 14) // px-3.5 = 14px
        .padding(.top, 14) // pt-3.5 = 14px  
        .padding(.bottom, 10) // pb-2.5 = 10px
    }
    
    private var expandedContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                if state.showAiChatFlow {
                    AgentStatusIndicator(
                        steps: state.aiSteps,
                        onStepClick: handleAiStepSelectForDetail,
                        activeHighlightId: state.activeHighlightId
                    )
                    .padding(.bottom, 12)
                } else {
                    // Show active view
                    activeViewContent
                }
            }
            .padding(.horizontal, 14) // Consistent with input section
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .frame(maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var activeViewContent: some View {
        switch state.activeView.id {
        case "taskListView":
            TaskListView(onTaskSelect: handleTaskSelectForDetail)
        case "loggingView":
            LoggingView()
        case "graphView":
            GraphView()
        case "billingView":
            BillingView()
        case "settingsView":
            SettingsView()
                .environmentObject(blurSettings)
        default:
            EmptyView()
        }
    }
    
    private var footerControls: some View {
        HStack {
            // Tools dropdown
            Button(action: { state.isToolMenuOpen.toggle() }) {
                HStack(spacing: 6) {
                    Text(state.activeTool?.name ?? "Tools")
                        .font(.textXS)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .frame(width: 14, height: 14) // h-3.5 w-3.5 from SWIFT2.md
                        .foregroundColor(Color.textSecondary(for: colorScheme))
                }
                .foregroundColor(Color.buttonText(for: colorScheme))
            }
            .buttonStyle(FooterButtonStyle())
            
            Spacer()
            
            // New Task button
            Button(action: handleNewTask) {
                Text("New Task")
                    .font(.textXS(.medium))
                    .foregroundColor(Color.footerButtonText(for: colorScheme))
            }
            .buttonStyle(FooterButtonStyle())
            
            Spacer()
            
            // View dropdown
            Button(action: { 
                if state.showAiChatFlow {
                    state.activeView = state.viewMenuItems.first { $0.id == "taskListView" } ?? state.viewMenuItems[0]
                    state.showAiChatFlow = false
                } else {
                    state.isViewMenuOpen.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Text(viewButtonTitle)
                        .font(.textXS)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .frame(width: 14, height: 14) // h-3.5 w-3.5 from SWIFT2.md
                        .foregroundColor(Color.textSecondary(for: colorScheme))
                }
                .foregroundColor(Color.buttonText(for: colorScheme))
            }
            .buttonStyle(FooterButtonStyle())
        }
        .padding(.horizontal, 12) // px-3 = 12px
        .padding(.vertical, 8) // py-2 = 8px
        .background(
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.borderColor(for: colorScheme))
                    .frame(height: 1)
                Color.clear
            }
        )
    }
    
    // MARK: - Computed Properties
    
    private var currentPlaceholder: String {
        state.activeTool != nil ? "Using \(state.activeTool!.name)..." : "Type your message..."
    }
    
    private var viewButtonTitle: String {
        if state.showAiChatFlow {
            return "Task View"
        } else if state.activeView.name.count > 10 {
            return String(state.activeView.name.prefix(7)) + "..."
        } else {
            return state.activeView.name
        }
    }
    
    // MARK: - Actions
    
    private func handleSubmit() {
        guard !state.inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !state.isProcessing else { return }
        
        state.expanded = true
        state.showAiChatFlow = true
        
        let userMessageContent = state.inputValue
        
        let newUserMessageStep = EnhancedStep(
            id: "user-\(UUID().uuidString)",
            type: .userMessage,
            text: userMessageContent
        )
        
        state.aiSteps.append(newUserMessageStep)
        state.activeHighlightId = newUserMessageStep.id
        state.inputValue = ""
        
        // Simulate AI response
        simulateAIResponse()
    }
    
    
    private func simulateAIResponse() {
        // Similar to simulateInitialConversation but for new messages
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            state.isProcessing = true
            state.processingComplete = false
            
            let synthesizingThought = EnhancedStep(
                id: "thought-synthesizing-\(UUID().uuidString)",
                type: .thought,
                text: "Processing your request...",
                status: .active
            )
            state.aiSteps.append(synthesizingThought)
            state.activeHighlightId = synthesizingThought.id
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Add tool steps
                let queryingStep = EnhancedStep(
                    id: "tool-1-\(UUID().uuidString)",
                    type: .tool,
                    text: "Querying knowledge base",
                    status: .active,
                    toolName: nil,
                    isIndented: true
                )
                state.aiSteps.append(queryingStep)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    // Complete first tool
                    if let index = state.aiSteps.firstIndex(where: { $0.id == queryingStep.id }) {
                        state.aiSteps[index].status = .completed
                    }
                    
                    // Add second tool
                    let analyzingStep = EnhancedStep(
                        id: "tool-2-\(UUID().uuidString)",
                        type: .tool,
                        text: "Analyzing patterns",
                        status: .active,
                        toolName: nil,
                        isIndented: true
                    )
                    state.aiSteps.append(analyzingStep)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        // Complete all
                        if let index = state.aiSteps.firstIndex(where: { $0.id == analyzingStep.id }) {
                            state.aiSteps[index].status = .completed
                        }
                        if let index = state.aiSteps.firstIndex(where: { $0.id == synthesizingThought.id }) {
                            state.aiSteps[index].status = .completed
                        }
                        
                        let aiResponseStep = EnhancedStep(
                            id: "response-\(UUID().uuidString)",
                            type: .response,
                            text: "Based on the analysis, here's what I found in your request.",
                            status: .completed
                        )
                        state.aiSteps.append(aiResponseStep)
                        state.activeHighlightId = aiResponseStep.id
                        
                        state.isProcessing = false
                        state.processingComplete = true
                    }
                }
            }
        }
    }
    
    private func handleNewTask() {
        state.aiSteps = []
        state.inputValue = ""
        state.activeHighlightId = nil
        state.showAiChatFlow = true
        state.expanded = true
        state.selectedItemForDetail = nil
        state.activeTool = nil
        isInputFocused = true
    }
    
    private func handleToolSelect(_ tool: MenuItem) {
        state.activeTool = state.activeTool?.id == tool.id ? nil : tool
        state.isToolMenuOpen = false
        isInputFocused = true
    }
    
    private func handleViewSelect(_ view: MenuItem) {
        guard !view.disabled else { return }
        state.activeView = view
        state.showAiChatFlow = false
        state.expanded = true
        state.selectedItemForDetail = nil
        state.isViewMenuOpen = false
        isInputFocused = true
    }
    
    private func handleTaskSelectForDetail(_ task: Task) {
        state.selectedItemForDetail = EnhancedStep(
            id: task.id,
            type: .thought,
            text: task.detailIdentifier,
            status: .active
        )
    }
    
    private func handleAiStepSelectForDetail(_ step: EnhancedStep) {
        if step.type == .tool || step.type == .thought || step.type == .response {
            state.selectedItemForDetail = step
        }
    }
}

// MARK: - Supporting Components

struct FooterButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isPressed ? Color.hoverBackground(for: colorScheme).opacity(2) :
                        isHovered ? Color.hoverBackground(for: colorScheme) :
                        Color.clear
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

// Visual effect view for true blur
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}