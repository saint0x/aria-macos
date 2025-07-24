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
    
    private let maxWidth: CGFloat = AppConfiguration.UI.maxChatWidth
    private let expandedHeight: CGFloat = AppConfiguration.UI.expandedChatHeight
    
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
                                    DropdownMenuView(items: state.toolMenuItems, onSelect: handleToolSelect, isOpen: $state.isToolMenuOpen, persistOnClick: true)
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
                                    DropdownMenuView(items: state.viewMenuItems, onSelect: handleViewSelect, isOpen: $state.isViewMenuOpen, persistOnClick: false)
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
                    tasks: state.mockTasks,
                    aiSteps: state.aiSteps
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
                    .zIndex(-1)
            }
            
            // Toast notifications positioned at top-right
            HStack {
                Spacer()
                VStack {
                    ToastContainer()
                    Spacer()
                }
            }
            .zIndex(10000) // Above all other UI elements
        }
        .onAppear {
            // Start collapsed like the React component
            state.expanded = false
            state.showAiChatFlow = false
            
            // Connect to notification service for SDK/firmware messages
            Task {
                await NotificationService.shared.connect()
            }
        }
        .onDisappear {
            // Disconnect notification service to clean up resources
            Task {
                await NotificationService.shared.disconnect()
            }
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
        .glassmorphic(cornerRadius: AppConfiguration.UI.chatCornerRadius)
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
        ScrollViewReader { scrollProxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
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
                    
                    // Invisible anchor for scroll-to-bottom functionality
                    if state.showAiChatFlow && !state.aiSteps.isEmpty {
                        Color.clear
                            .frame(height: 1)
                            .id("bottom-anchor")
                    }
                }
                .padding(.horizontal, AppConfiguration.UI.chatPadding)
                .padding(.top, 4)
                .padding(.bottom, AppConfiguration.UI.messagePadding)
            }
            .frame(maxHeight: .infinity)
            .onChange(of: state.aiSteps.count) {
                handleNewMessage(scrollProxy: scrollProxy)
            }
            .onChange(of: state.activeHighlightId) {
                handleHighlightChange(scrollProxy: scrollProxy)
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        state.isUserScrolling = true
                    }
                    .onEnded { _ in
                        // Allow auto-scroll again after user stops scrolling
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.state.isUserScrolling = false
                        }
                    }
            )
        }
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
                    Text(state.activeTool?.name ?? "Utility")
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
                print("GlassmorphicChatbar: View button clicked - showAiChatFlow: \(state.showAiChatFlow), isViewMenuOpen: \(state.isViewMenuOpen)")
                
                // Always show the dropdown menu when clicked
                state.isViewMenuOpen.toggle()
                print("GlassmorphicChatbar: View menu toggled to: \(state.isViewMenuOpen)")
                
                // If AI chat flow is active, also switch to task view
                if state.showAiChatFlow {
                    state.activeView = state.viewMenuItems.first { $0.id == "taskListView" } ?? state.viewMenuItems[0]
                    state.showAiChatFlow = false
                    print("GlassmorphicChatbar: Switched from AI flow to task view")
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
        
        state.addStep(newUserMessageStep)
        state.activeHighlightId = newUserMessageStep.id
        state.inputValue = ""
        
        // Execute turn using ChatService
        Task {
            await executeAIResponse(input: userMessageContent)
        }
    }
    
    
    private func executeAIResponse(input: String) async {
        state.isProcessing = true
        state.processingComplete = false
        
        // Add initial acknowledgment as a visible response
        let acknowledgmentId = "ack-\(UUID().uuidString)"
        let acknowledgmentStep = EnhancedStep(
            id: acknowledgmentId,
            type: .response,
            text: "Let me help you with that...",
            status: .active,
            metadata: MessageMetadata(isStatus: false, isFinal: false, messageType: "acknowledgment")
        )
        state.addStep(acknowledgmentStep)
        state.activeHighlightId = acknowledgmentStep.id
        
        var eventCount = 0
        var receivedFinalResponse = false
        var hasRemovedAcknowledgment = false
        
        do {
            // Create a simple actor to hold mutable state
            let turnState = TurnState()
            
            print("GlassmorphicChatbar: Starting executeTurn for input: '\(input)'")
            
            try await state.chatService.executeTurn(input: input) { event in
                Task { @MainActor in
                    eventCount += 1
                    print("GlassmorphicChatbar: Received event #\(eventCount): \(event)")
                    
                    // Remove acknowledgment on first meaningful event
                    if !hasRemovedAcknowledgment {
                        switch event {
                        case .message(let msg) where msg.metadata?.messageType != "acknowledgment":
                            fallthrough
                        case .toolCall, .finalResponse:
                            // Remove the acknowledgment step
                            if let index = self.state.aiSteps.firstIndex(where: { $0.id == acknowledgmentId }) {
                                self.state.aiSteps.remove(at: index)
                            }
                            hasRemovedAcknowledgment = true
                        default:
                            break
                        }
                    }
                    
                    switch event {
                    case .message(let message):
                        // Skip user messages from events - we already added them when submitting
                        if message.role == .user {
                            print("Skipping duplicate user message from event stream")
                            break
                        }
                        
                        // Skip assistant response messages - they will be handled by finalResponse event
                        if message.role == .assistant {
                            print("✅ SKIPPING assistant response message (ID: \(message.id)) - will be handled by finalResponse event")
                            break
                        }
                        
                        // Extract rich metadata from detailed_results
                        var detailedResults: [String: Any]?
                        var thinkingSteps: [ThinkingStep]?
                        var executionContext: ExecutionContext?
                        
                        if let meta = message.metadata,
                           let detailsData = meta.detailedResults {
                            // Convert AnyCodable to Any for processing by encoding/decoding
                            do {
                                let encoder = JSONEncoder()
                                let decoder = JSONDecoder()
                                let jsonData = try encoder.encode(detailsData)
                                if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                                    detailedResults = jsonObject
                                    
                                    // Extract thinking steps from detailed_results.thoughts
                                    if let thoughts = jsonObject["thoughts"] as? [[String: Any]] {
                                        thinkingSteps = thoughts.compactMap { thoughtData in
                                            guard let step = thoughtData["step"] as? Int,
                                                  let type = thoughtData["type"] as? String,
                                                  let content = thoughtData["content"] as? String else {
                                                return nil
                                            }
                                            
                                            let confidence = thoughtData["confidence"] as? Double
                                            return ThinkingStep(
                                                step: step,
                                                type: type,
                                                content: content,
                                                confidence: confidence,
                                                timestamp: Date()
                                            )
                                        }
                                    }
                                    
                                    // Extract execution context if available
                                    if let contextData = jsonObject["executionContext"] as? [String: Any] {
                                        executionContext = ExecutionContext(
                                            duration_ms: contextData["duration_ms"] as? Int,
                                            memory_used: contextData["memory_used"] as? String,
                                            tokens_consumed: contextData["tokens_consumed"] as? Int,
                                            cpu_percent: contextData["cpu_percent"] as? Double,
                                            execution_time_ms: contextData["execution_time_ms"] as? Int,
                                            inputValidation: contextData["inputValidation"] as? String
                                        )
                                    }
                                }
                            } catch {
                                print("Error converting AnyCodable to Any: \(error)")
                            }
                        }
                        
                        var step = EnhancedStep(
                            id: "msg-\(message.id)",
                            type: self.mapMessageRoleToStepType(message.role),
                            text: message.content,
                            status: .active,
                            metadata: message.metadata
                        )
                        
                        // Assign rich metadata (convert to Data for Sendable compliance)
                        if let detailedResults = detailedResults {
                            do {
                                step.detailedResultsData = try JSONSerialization.data(withJSONObject: detailedResults)
                            } catch {
                                print("Failed to serialize detailedResults: \(error)")
                            }
                        }
                        step.thinkingSteps = thinkingSteps
                        step.executionContext = executionContext
                        
                        // Debug logging for metadata
                        if let meta = message.metadata {
                            print("🔍 Message: '\(message.content.prefix(50))...' - Metadata: isStatus=\(meta.isStatus), isFinal=\(meta.isFinal), messageType=\(meta.messageType)")
                            
                            // Log detailed results structure
                            if let detailsData = meta.detailedResults {
                                print("📊 DetailedResults keys: \(Array(detailsData.keys))")
                                
                                // Log specific fields we're looking for
                                if detailsData["thoughts"] != nil {
                                    print("💭 Found 'thoughts' field in detailed results")
                                } else {
                                    print("❌ No 'thoughts' field found in detailed results")
                                }
                                
                                if detailsData["executionContext"] != nil {
                                    print("⚙️ Found 'executionContext' field in detailed results")
                                } else {
                                    print("❌ No 'executionContext' field found in detailed results")
                                }
                            } else {
                                print("❌ No detailed results in metadata")
                            }
                            
                            if let thinkingSteps = thinkingSteps {
                                print("✅ Captured \(thinkingSteps.count) thinking steps")
                                for (index, thinking) in thinkingSteps.enumerated() {
                                    print("  Step \(thinking.step): \(thinking.type) - \(thinking.content.prefix(50))...")
                                }
                            } else {
                                print("❌ No thinking steps extracted")
                            }
                            
                            if let context = executionContext {
                                print("⚙️ Execution context: duration=\(context.duration_ms ?? 0)ms, memory=\(context.memory_used ?? "N/A")")
                            } else {
                                print("❌ No execution context extracted")
                            }
                        } else {
                            print("❌ Message: '\(message.content.prefix(50))...' - No metadata, role=\(message.role)")
                        }
                        
                        self.state.addStep(step)
                        self.state.activeHighlightId = step.id
                        
                        if message.role == .thought {
                            await turnState.setActiveThoughtId(step.id)
                        }
                        
                    case .toolCall(let toolCall):
                        // Debug log tool parameters
                        print("Tool call: \(toolCall.toolName) with params: \(toolCall.parameters)")
                        
                        let step = EnhancedStep(
                            id: "tool-\(toolCall.id)",
                            type: .tool,
                            text: toolCall.toolName,
                            status: .active,
                            toolName: toolCall.toolName,
                            isIndented: true,
                            toolParameters: toolCall.parameters
                        )
                        self.state.addStep(step)
                        await turnState.setToolId(toolCall.toolName, stepId: step.id)
                        
                    case .toolResult(let toolResult):
                        // Debug log tool result
                        print("Tool result for \(toolResult.toolName): success=\(toolResult.success), output=\(toolResult.output.prefix(100))...")
                        
                        // Update the corresponding tool step with result
                        if let stepId = await turnState.getToolId(toolResult.toolName),
                           let index = self.state.aiSteps.firstIndex(where: { $0.id == stepId }) {
                            self.state.aiSteps[index].status = toolResult.success ? .completed : .failed
                            self.state.aiSteps[index].toolResult = toolResult.output
                            if let error = toolResult.error {
                                self.state.aiSteps[index].errorMessage = error
                            }
                            
                            // Capture rich JSON results from result_json field
                            if let resultData = toolResult.output.data(using: .utf8),
                               let _ = try? JSONSerialization.jsonObject(with: resultData, options: []) as? [String: Any] {
                                self.state.aiSteps[index].rawResultJSONData = resultData
                                print("  Captured rich JSON result data")
                            }
                            
                            print("Updated tool step at index \(index) with result")
                        } else {
                            print("Warning: Could not find tool step for \(toolResult.toolName)")
                        }
                        
                    case .finalResponse(let response):
                        // Skip duplicate finalResponse events with same content
                        if receivedFinalResponse {
                            print("✅ SKIPPING duplicate finalResponse event")
                            break
                        }
                        
                        print("✅ PROCESSING finalResponse event - this will be the visible message")
                        receivedFinalResponse = true
                        // Complete any active thought
                        if let thoughtId = await turnState.getActiveThoughtId(),
                           let index = self.state.aiSteps.firstIndex(where: { $0.id == thoughtId }) {
                            self.state.aiSteps[index].status = .completed
                        }
                        
                        let responseStep = EnhancedStep(
                            id: "response-\(UUID().uuidString)",
                            type: .response,
                            text: response,
                            status: .completed,
                            metadata: MessageMetadata(isStatus: false, isFinal: true, messageType: "response")
                        )
                        self.state.addStep(responseStep)
                        self.state.activeHighlightId = responseStep.id
                    }
                }
            }
        } catch {
            print("GlassmorphicChatbar: Error in executeTurn: \(error)")
            // Handle error
            let errorStep = EnhancedStep(
                id: "error-\(UUID().uuidString)",
                type: .response,
                text: "Error: \(error.localizedDescription)",
                status: .failed
            )
            state.addStep(errorStep)
        }
        
        print("GlassmorphicChatbar: Execution complete. Events received: \(eventCount), Final response: \(receivedFinalResponse)")
        
        state.isProcessing = false
        state.processingComplete = true
        
        // With simplified visibility rules, responses should now be visible automatically
        
        // If we never removed the acknowledgment and no final response, update it to show completion
        if !hasRemovedAcknowledgment && !receivedFinalResponse {
            if let index = state.aiSteps.firstIndex(where: { $0.id == acknowledgmentId }) {
                // Create a new step with updated text and status
                let updatedStep = EnhancedStep(
                    id: acknowledgmentId,
                    type: .response,
                    text: "I've processed your request. Please let me know if you need anything else.",
                    status: .completed,
                    metadata: MessageMetadata(isStatus: false, isFinal: false, messageType: "acknowledgment")
                )
                state.aiSteps[index] = updatedStep
            }
        }
    }
    
    private func mapMessageRoleToStepType(_ role: MessageRole) -> StepType {
        switch role {
        case .user:
            return .userMessage
        case .assistant:
            return .response
        case .thought:
            return .thought
        case .tool:
            return .tool
        case .system:
            return .thought
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
        
        // Create new session
        Task {
            do {
                _ = try await state.sessionManager.createSession()
            } catch {
                // Handle error - show in UI
                let errorStep = EnhancedStep(
                    id: "error-\(UUID().uuidString)",
                    type: .response,
                    text: "Failed to create new session: \(error.localizedDescription)",
                    status: .failed
                )
                state.addStep(errorStep)
            }
        }
    }
    
    private func handleToolSelect(_ tool: MenuItem) {
        state.activeTool = state.activeTool?.id == tool.id ? nil : tool
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
    
    private func handleTaskSelectForDetail(_ task: AriaTask) {
        state.expanded = true
        state.isLoadingHistory = true
        state.selectedItemForDetail = nil // Clear any existing detail pane
        
        Task {
            do {
                try await ChatService.shared.loadChatHistory(for: task.id, state: state)
                await MainActor.run {
                    state.isLoadingHistory = false
                    print("GlassmorphicChatbar: Successfully loaded chat history for task: \(task.id)")
                }
            } catch {
                await MainActor.run {
                    state.isLoadingHistory = false
                    print("GlassmorphicChatbar: Error loading chat history for task \(task.id): \(error)")
                    // Optionally show error state or fallback to detail view
                }
            }
        }
    }
    
    private func handleAiStepSelectForDetail(_ step: EnhancedStep) {
        if step.type == .tool || step.type == .thought || step.type == .response {
            state.selectedItemForDetail = step
        }
    }
    
    
    // MARK: - Production-Ready Auto-Scroll System
    
    private func handleNewMessage(scrollProxy: ScrollViewProxy) {
        // Only auto-scroll if user is not manually scrolling and we should auto-scroll
        guard state.shouldAutoScroll && !state.isUserScrolling && state.showAiChatFlow else { return }
        
        // Debounce rapid message additions
        state.scrollDebounceTimer?.invalidate()
        state.scrollDebounceTimer = Timer.scheduledTimer(withTimeInterval: AppConfiguration.UI.scrollDebounceInterval, repeats: false) { _ in
            DispatchQueue.main.async {
                self.performAutoScroll(scrollProxy: scrollProxy)
            }
        }
    }
    
    private func handleHighlightChange(scrollProxy: ScrollViewProxy) {
        // When highlighting a specific message, always scroll to it
        if let highlightId = state.activeHighlightId {
            withAnimation(.easeOut(duration: 0.4)) {
                scrollProxy.scrollTo(highlightId, anchor: .center)
            }
        }
    }
    
    private func resetAutoScrollAfterDelay() {
        // Reset auto-scroll flag after user interaction ends
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !self.state.isUserScrolling {
                self.state.shouldAutoScroll = true
            }
        }
    }
    
    private func performAutoScroll(scrollProxy: ScrollViewProxy) {
        guard !state.aiSteps.isEmpty else { return }
        
        let animation = AnimationManager.shared.coordinatedScrollAnimation()
        withAnimation(animation) {
            scrollProxy.scrollTo("bottom-anchor", anchor: .bottom)
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

// MARK: - Turn State Actor

private actor TurnState {
    private var activeThoughtId: String?
    private var activeToolIds: [String: String] = [:] // toolName -> stepId
    
    func setActiveThoughtId(_ id: String) {
        activeThoughtId = id
    }
    
    func getActiveThoughtId() -> String? {
        return activeThoughtId
    }
    
    func setToolId(_ toolName: String, stepId: String) {
        activeToolIds[toolName] = stepId
    }
    
    func getToolId(_ toolName: String) -> String? {
        return activeToolIds[toolName]
    }
}