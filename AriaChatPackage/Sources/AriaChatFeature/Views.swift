import SwiftUI

// MARK: - Task List View
struct TaskListView: View {
    let onTaskSelect: (AriaTask) -> Void
    @StateObject private var taskManager = TaskManager.shared
    @State private var isInitialLoad = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Active Tasks")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                if taskManager.isLoadingTasks && !isInitialLoad {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.bottom, 4)
            
            if taskManager.tasks.isEmpty && !taskManager.isLoadingTasks {
                Text("No tasks available")
                    .font(.textSM)
                    .foregroundColor(Color.textSecondary(for: .light))
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(taskManager.tasks, id: \.id) { task in
                            TaskRow(
                                task: convertTaskResponseToAriaTask(task),
                                onSelect: { onTaskSelect(convertTaskResponseToAriaTask(task)) }
                            )
                        }
                        
                        if taskManager.hasMoreTasks && !taskManager.isLoadingTasks {
                            Button(action: {
                                Task {
                                    try? await taskManager.loadMoreTasks()
                                }
                            }) {
                                Text("Load More")
                                    .font(.textSM)
                                    .foregroundColor(Color.appleBlue)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
            
            if let error = taskManager.taskError {
                Text("Error: \(error.localizedDescription)")
                    .font(.textXS)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .onAppear {
            if isInitialLoad {
                Task {
                    isInitialLoad = false
                    print("TaskListView: Starting to load tasks...")
                    do {
                        // Now list tasks
                        try await taskManager.listTasks(refresh: true)
                        print("TaskListView: Listed tasks successfully")
                    } catch {
                        print("TaskListView: Error loading tasks: \(error)")
                    }
                }
            }
        }
    }
    
    private func convertTaskResponseToAriaTask(_ taskResponse: TaskResponse) -> AriaTask {
        AriaTask(
            id: taskResponse.id,
            title: "Task \(taskResponse.id.prefix(8))",
            detailIdentifier: taskResponse.sessionId ?? "",
            status: taskManager.mapTaskStatus(taskResponse.status),
            timestamp: taskResponse.createdAt
        )
    }
}

struct TaskRow: View {
    let task: AriaTask
    let onSelect: () -> Void
    
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    var statusDotColor: Color {
        switch task.status {
        case .completed, .running:
            return Color(red: 52/255, green: 199/255, blue: 89/255) // apple-green
        case .inProgress, .paused:
            return Color(red: 245/255, green: 158/255, blue: 11/255) // orange/yellow
        case .failed:
            return Color(red: 239/255, green: 68/255, blue: 68/255) // red-500
        case .pending:
            return colorScheme == .dark ? Color(white: 0.4) : Color.gray
        }
    }
    
    var statusTextColor: Color {
        switch task.status {
        case .completed, .running:
            return colorScheme == .dark ? Color.green.opacity(0.7) : Color.green.opacity(0.8)
        case .inProgress, .paused:
            return colorScheme == .dark ? Color.orange.opacity(0.7) : Color.orange.opacity(0.8)
        case .failed:
            return colorScheme == .dark ? Color.red.opacity(0.7) : Color.red.opacity(0.8)
        case .pending:
            return Color.textSecondary(for: colorScheme)
        }
    }
    
    var statusText: String {
        switch task.status {
        case .inProgress: return "Paused"
        default: return task.status.rawValue
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) { // mt-1 -> 4pt spacing
                    Text(task.title)
                        .font(.system(size: 14)) // text-sm
                        .foregroundColor(colorScheme == .dark ? Color.white : Color(red: 58/255, green: 58/255, blue: 60/255)) // text-neutral-800 dark:text-neutral-100
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(task.title) // Tooltip
                    
                    // Status Area
                    HStack(spacing: 8) { // mr-2 on dot -> 8pt spacing
                        // Status Dot
                        Circle()
                            .fill(statusDotColor)
                            .frame(width: 6, height: 6) // h-1.5 w-1.5
                        
                        // Status Text
                        Text(statusText)
                            .font(.system(size: 12)) // text-xs
                            .foregroundColor(statusTextColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Chevron Icon
                Image(systemName: "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20) // h-5 w-5
                    .foregroundColor(colorScheme == .dark ? Color(white: 0.6) : Color.gray) // text-neutral-500 dark:text-neutral-400
            }
            .padding(12) // p-3 = 12pt
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 16) // rounded-xl = 16pt
                .fill(isHovered ? 
                    (colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08)) : 
                    (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                )
        )
        .appleShadowSmall() // shadow-apple-sm
        .animation(.linear(duration: 0.15), value: isHovered) // transition-colors duration-150
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

// MARK: - Logging View
struct LoggingView: View {
    @State private var selectedTimeframe = "7d"
    @State private var isTimeframeMenuOpen = false
    @Environment(\.colorScheme) var colorScheme
    
    let timeframeOptions = [
        ("24h", "Last 24 hours"),
        ("today", "Today"),
        ("7d", "Last 7 days"),
        ("30d", "Last 30 days"),
        ("all", "All time")
    ]
    
    var activeTimeframeLabel: String {
        timeframeOptions.first { $0.0 == selectedTimeframe }?.0 ?? "7d"
    }
    
    @State private var logs: [LogEntry] = [
        LogEntry(timestamp: Date(), level: "INFO", source: "System", message: "System initialized"),
        LogEntry(timestamp: Date().addingTimeInterval(-60), level: "INFO", source: "Network", message: "Connected to server"),
        LogEntry(timestamp: Date().addingTimeInterval(-120), level: "SUCCESS", source: "Auth", message: "Authentication successful"),
        LogEntry(timestamp: Date().addingTimeInterval(-180), level: "INFO", source: "Data", message: "Loading user data..."),
        LogEntry(timestamp: Date().addingTimeInterval(-240), level: "WARN", source: "API", message: "Rate limit approaching"),
        LogEntry(timestamp: Date().addingTimeInterval(-300), level: "ERROR", source: "Database", message: "Connection timeout"),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with timeframe dropdown
            HStack {
                Text("Activity Logs")
                    .font(.textBase(.semibold))
                
                Spacer()
                
                Button(action: { isTimeframeMenuOpen.toggle() }) {
                    HStack(spacing: 4) {
                        Text(activeTimeframeLabel)
                            .font(.textXS)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color.buttonText(for: colorScheme))
                }
                .buttonStyle(FooterButtonStyle())
                .overlay(
                    Group {
                        if isTimeframeMenuOpen {
                            VStack(spacing: 0) {
                                ForEach(timeframeOptions, id: \.0) { option in
                                    Button(action: {
                                        selectedTimeframe = option.0
                                        isTimeframeMenuOpen = false
                                    }) {
                                        HStack {
                                            Text(option.1)
                                                .font(.textXS)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .hoverHighlight()
                                }
                            }
                            .padding(6)
                            .frame(width: 150)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.glassmorphicBackground(for: colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .offset(y: 35)
                            .zIndex(1000)
                        }
                    }
                )
            }
            
            // Log container
            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    Text("Timestamp")
                        .frame(width: 120, alignment: .leading)
                    Text("Level")
                        .frame(width: 60, alignment: .leading)
                    Text("Source")
                        .frame(width: 80, alignment: .leading)
                    Text("Message")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.textXS(.medium))
                .foregroundColor(Color.textSecondary(for: colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
                
                Divider()
                
                // Log entries
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(logs) { entry in
                            LogEntryRow(entry: entry)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 250)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.glassmorphicBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .slideUpFade(isVisible: true)
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: String
    let source: String
    let message: String
    var details: [String: Any]? = nil
}

struct LogEntryRow: View {
    let entry: LogEntry
    @State private var isExpanded = false
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    var levelColor: Color {
        switch entry.level {
        case "ERROR": return .red
        case "WARN": return .orange
        case "SUCCESS": return .green
        default: return Color.textSecondary(for: colorScheme)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Timestamp
                Text(entry.timestamp, style: .time)
                    .frame(width: 120, alignment: .leading)
                    .font(.monoXS)
                
                // Level
                Text(entry.level)
                    .frame(width: 60, alignment: .leading)
                    .font(.textXS) // Remove medium weight to match original
                    .foregroundColor(levelColor)
                
                // Source
                Text(entry.source)
                    .frame(width: 80, alignment: .leading)
                    .font(.textXS)
                
                // Message
                Text(entry.message)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.textXS)
                    .lineLimit(1)
                
                // Expand chevron if details exist
                if entry.details != nil {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .font(.system(size: 10))
                        .foregroundColor(Color.textTertiary(for: colorScheme))
                }
            }
            .foregroundColor(Color.textPrimary(for: colorScheme))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(isHovered ? Color.hoverBackground(for: colorScheme) : Color.clear)
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                if entry.details != nil {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            }
            
            // Expanded details
            if isExpanded, let details = entry.details {
                VStack(alignment: .leading) {
                    if let jsonData = try? JSONSerialization.data(withJSONObject: details, options: .prettyPrinted),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        Text(jsonString)
                            .font(.monoXS)
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                            )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .transition(.asymmetric(
                    insertion: .offset(y: -10).combined(with: .opacity),
                    removal: .offset(y: -5).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Graph View
struct GraphView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Graph View")
                .font(.textBase(.semibold))
                .foregroundColor(Color.textPrimary(for: colorScheme))
            
            VStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 48))
                    .foregroundColor(Color.textTertiary(for: colorScheme))
                
                Text("Coming Soon")
                    .font(.textSM)
                    .foregroundColor(Color.textSecondary(for: colorScheme))
                
                Text("Data visualization and analytics will be available here")
                    .font(.textXS)
                    .foregroundColor(Color.textTertiary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .slideUpFade(isVisible: true)
    }
}

// MARK: - Legacy Billing View (replaced by BillingView.swift)
struct BillingViewOld: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var usagePercentage: CGFloat = 0.2341 // 2,341 / 10,000
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text("Billing & Usage")
                .font(.textBase(.semibold))
                .foregroundColor(Color.textPrimary(for: colorScheme))
            
            // Billing info card
            VStack(alignment: .leading, spacing: 16) {
                // Plan info
                HStack {
                    Text("Current Plan")
                        .font(.textSM)
                        .foregroundColor(Color.textSecondary(for: colorScheme))
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Pro")
                            .font(.textSM(.medium))
                            .foregroundColor(Color.appleBlue)
                        Image(systemName: "sparkle")
                            .font(.system(size: 12))
                            .foregroundColor(Color.appleBlue)
                    }
                }
                
                Divider()
                    .background(Color.borderColor(for: colorScheme))
                
                // Usage section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("API Usage")
                            .font(.textSM)
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                        Spacer()
                        Text("2,341 / 10,000 requests")
                            .font(.monoXS)
                            .foregroundColor(Color.textPrimary(for: colorScheme))
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                                .frame(height: 8)
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.appleBlue.opacity(0.8),
                                            Color.appleBlue
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * usagePercentage, height: 8)
                                .animation(.easeOut(duration: 0.6), value: usagePercentage)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("23.41% used this month")
                        .font(.textXS)
                        .foregroundColor(Color.textTertiary(for: colorScheme))
                }
                
                Divider()
                    .background(Color.borderColor(for: colorScheme))
                
                // Billing date
                HStack {
                    Text("Next billing date")
                        .font(.textSM)
                        .foregroundColor(Color.textSecondary(for: colorScheme))
                    Spacer()
                    Text("Feb 1, 2024")
                        .font(.textSM)
                        .foregroundColor(Color.textPrimary(for: colorScheme))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.glassmorphicBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // Action links
            HStack(spacing: 16) {
                InteractiveButton(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 14))
                        Text("Upgrade Plan")
                            .font(.textSM)
                    }
                    .foregroundColor(Color.appleBlue)
                }
                
                InteractiveButton(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14))
                        Text("Usage History")
                            .font(.textSM)
                    }
                    .foregroundColor(Color.buttonText(for: colorScheme))
                }
                
                Spacer()
            }
        }
        .slideUpFade(isVisible: true)
        .onAppear {
            // Animate the progress bar on appear
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                usagePercentage = 0.2341
            }
        }
    }
}


// MARK: - Tool Upload Success Display
struct ToolUploadSuccessDisplay: View {
    let message: String
    @Environment(\.colorScheme) var colorScheme
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.appleGreen)
                .font(.system(size: 16))
            
            Text(message)
                .font(.textSM)
                .foregroundColor(Color.textPrimary(for: colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appleGreen.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.appleGreen.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(AnimationSystem.expandIn) {
                isVisible = true
            }
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isVisible = false
                }
            }
        }
    }
}

// MARK: - Step Detail Pane
struct StepDetailPane: View {
    let step: EnhancedStep
    let onClose: () -> Void
    let tasks: [AriaTask]
    
    @State private var viewMode: ViewMode = .richText
    @State private var expandedSections = Set<String>()
    @Environment(\.colorScheme) var colorScheme
    
    enum ViewMode {
        case richText
        case json
    }
    
    var detailContent: StepDetailsContent? {
        getStepDetailsContent(for: step, tasks: tasks)
    }
    
    var title: String {
        if step.type == .tool {
            return step.toolName ?? "Tool Details"
        } else if step.text.hasPrefix("TASK_DETAIL_") {
            let taskId = step.text.replacingOccurrences(of: "TASK_DETAIL_", with: "")
            if let task = tasks.first(where: { $0.id == taskId }) {
                return task.title
            }
        }
        return step.text.count > 50 ? String(step.text.prefix(47)) + "..." : step.text
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(NSColor.secondaryLabelColor))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.1))
            
            Divider()
            
            // Content
            if let content = detailContent {
                ScrollView {
                    VStack(spacing: 0) {
                        // Accordion sections
                        AccordionSection(
                            title: content.isAiStep ? "Input" : "Task Details",
                            content: content.input,
                            viewMode: $viewMode,
                            isExpanded: expandedSections.contains("input")
                        ) {
                            toggleSection("input")
                        }
                        
                        Divider()
                        
                        AccordionSection(
                            title: content.isAiStep ? "Thinking Process" : "Progress & Status",
                            content: content.thinking,
                            viewMode: $viewMode,
                            isExpanded: expandedSections.contains("thinking")
                        ) {
                            toggleSection("thinking")
                        }
                        
                        Divider()
                        
                        AccordionSection(
                            title: content.isAiStep ? "Output" : "Additional Info",
                            content: content.output,
                            viewMode: $viewMode,
                            isExpanded: expandedSections.contains("output")
                        ) {
                            toggleSection("output")
                        }
                    }
                }
                .background(Color(NSColor.windowBackgroundColor).opacity(0.05))
            }
            
            Divider()
            
            // Footer
            HStack {
                if let taskStatus = detailContent?.taskStatus {
                    StatusBar(status: taskStatus)
                } else if detailContent?.isAiStep == true {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        Text("Status: Success")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Button(action: { viewMode = viewMode == .richText ? .json : .richText }) {
                    Text(viewMode == .richText ? "View JSON" : "View Rich Text")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(NSColor.secondaryLabelColor))
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.1))
        }
        .frame(width: 320, height: 450)
        .glassmorphic(cornerRadius: 16)
        .appleShadow()
        .onAppear {
            // Default expand first section
            expandedSections.insert("input")
        }
    }
    
    private func toggleSection(_ section: String) {
        if expandedSections.contains(section) {
            expandedSections.remove(section)
        } else {
            expandedSections.insert(section)
        }
    }
}

// Supporting views for StepDetailPane
struct AccordionSection: View {
    let title: String
    let content: SectionContent
    @Binding var viewMode: StepDetailPane.ViewMode
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .font(.system(size: 11))
                }
                .foregroundColor(Color(NSColor.labelColor))
                .padding()
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Group {
                    if viewMode == .richText {
                        Text(content.richText)
                            .font(.system(size: 12))
                            .foregroundColor(Color(NSColor.secondaryLabelColor))
                            .padding(.horizontal)
                            .padding(.bottom)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(content.jsonString)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color(NSColor.secondaryLabelColor))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                )
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .offset(y: -10).combined(with: .opacity),
                    removal: .offset(y: -5).combined(with: .opacity)
                ))
            }
        }
        .animation(AnimationSystem.expandIn, value: isExpanded)
    }
}

struct StatusBar: View {
    let status: String
    
    var statusInfo: (text: String, color: Color, icon: String) {
        switch status.lowercased() {
        case "completed":
            return ("Completed", .green, "checkmark.circle.fill")
        case "failed":
            return ("Failed", .red, "xmark.circle.fill")
        case "in progress":
            return ("In Progress", .orange, "arrow.triangle.2.circlepath")
        default:
            return ("Pending", .gray, "clock")
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusInfo.icon)
                .foregroundColor(statusInfo.color)
                .font(.system(size: 14))
            Text("Status: \(statusInfo.text)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(statusInfo.color)
        }
    }
}

// Data structures
struct SectionContent {
    let richText: String
    let jsonData: [String: Any]
    
    var jsonString: String {
        guard let data = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}

struct StepDetailsContent {
    let input: SectionContent
    let thinking: SectionContent
    let output: SectionContent
    let taskStatus: String?
    let isAiStep: Bool
}

// Helper function to get step details content
func getStepDetailsContent(for step: EnhancedStep, tasks: [AriaTask]) -> StepDetailsContent? {
    if step.text.hasPrefix("TASK_DETAIL_") {
        let taskId = step.text.replacingOccurrences(of: "TASK_DETAIL_", with: "")
        if let task = tasks.first(where: { $0.id == taskId }) {
            return StepDetailsContent(
                input: SectionContent(
                    richText: "Task Name: \(task.title)\nStatus: \(task.status.rawValue)\nTimestamp: \(task.timestamp)",
                    jsonData: ["title": task.title, "status": task.status.rawValue, "id": task.id]
                ),
                thinking: SectionContent(
                    richText: "Current progress information",
                    jsonData: ["progress": "In progress"]
                ),
                output: SectionContent(
                    richText: "Task ID: \(task.id)",
                    jsonData: ["id": task.id]
                ),
                taskStatus: task.status.rawValue,
                isAiStep: false
            )
        }
    } else if step.type == .tool {
        // Format parameters
        var parametersText = "Tool: \(step.toolName ?? "Unknown")\nStatus: \(step.status.rawValue)"
        var parametersJson: [String: Any] = ["toolName": step.toolName ?? "", "status": step.status.rawValue]
        
        if let params = step.toolParameters, !params.isEmpty {
            parametersText += "\n\nParameters:"
            parametersJson["parameters"] = params
            for (key, value) in params {
                parametersText += "\n  \(key): \(value)"
            }
        }
        
        // Format results
        var outputText = "Tool execution "
        var outputJson: [String: Any] = [:]
        
        if step.status == .failed {
            outputText += "failed"
            if let error = step.errorMessage {
                outputText += "\nError: \(error)"
                outputJson["error"] = error
            }
        } else if let result = step.toolResult {
            outputText = "Result:\n\(result)"
            // Try to parse as JSON for better display
            if let data = result.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) {
                outputJson["result"] = json
            } else {
                outputJson["result"] = result
            }
        } else if step.status == .active {
            outputText = "Tool is currently executing..."
        } else {
            outputText = "No output available"
        }
        
        return StepDetailsContent(
            input: SectionContent(
                richText: parametersText,
                jsonData: parametersJson
            ),
            thinking: SectionContent(
                richText: "Status: \(step.status.rawValue)\nExecution: \(step.text)",
                jsonData: ["status": step.status.rawValue, "execution": step.text]
            ),
            output: SectionContent(
                richText: outputText,
                jsonData: outputJson
            ),
            taskStatus: nil,
            isAiStep: true
        )
    }
    
    // Default for other step types
    return StepDetailsContent(
        input: SectionContent(
            richText: "Details for: \(step.text)",
            jsonData: ["text": step.text]
        ),
        thinking: SectionContent(
            richText: "Processing information",
            jsonData: ["processing": true]
        ),
        output: SectionContent(
            richText: "No specific output",
            jsonData: [:]
        ),
        taskStatus: nil,
        isAiStep: true
    )
}