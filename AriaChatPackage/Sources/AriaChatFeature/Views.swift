import SwiftUI

// MARK: - Task List View
struct TaskListView: View {
    let onTaskSelect: (AriaTask) -> Void
    
    @StateObject private var taskManager = TaskManager.shared
    @StateObject private var chatSessionManager = ChatSessionManager.shared
    
    @State private var selectedContentType: ContentType = .chats
    @State private var isContentTypeMenuOpen = false
    @State private var isInitialLoad = true
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Active Tasks")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.textPrimary(for: colorScheme))
                
                Spacer()
                
                // Loading indicator
                if (selectedContentType == .chats ? chatSessionManager.isLoadingSessions : taskManager.isLoadingTasks) && !isInitialLoad {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                // Content Type Dropdown
                Button(action: { isContentTypeMenuOpen.toggle() }) {
                    HStack(spacing: 6) {
                        Text(selectedContentType.displayName)
                            .font(.textXS)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color.buttonText(for: colorScheme))
                }
                .buttonStyle(FooterButtonStyle())
            }
            .padding(.bottom, 4)
            
            // Content based on selected type
            ContentListView(
                contentType: selectedContentType,
                chatSessionManager: chatSessionManager,
                taskManager: taskManager,
                onTaskSelect: onTaskSelect
            )
        }
        .overlay(alignment: .topTrailing) {
            // Content Type Dropdown Menu
            if isContentTypeMenuOpen {
                VStack(spacing: 0) {
                    ForEach(ContentType.allCases, id: \.self) { contentType in
                        Button(action: {
                            selectedContentType = contentType
                            isContentTypeMenuOpen = false
                        }) {
                            HStack {
                                Text(contentType.displayName)
                                    .font(.textXS)
                                    .foregroundColor(
                                        !contentType.isImplemented ?
                                        Color.textTertiary(for: colorScheme) :
                                        (selectedContentType == contentType ?
                                        Color.buttonText(for: colorScheme) :
                                        Color.textSecondary(for: colorScheme))
                                    )
                                
                                Spacer()
                                
                                if selectedContentType == contentType {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color.buttonText(for: colorScheme))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!contentType.isImplemented)
                        .hoverHighlight()
                    }
                }
                .padding(6)
                .frame(width: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.glassmorphicBackground(for: colorScheme))
                        .background(
                            VisualEffectView(material: .menu, blendingMode: .withinWindow)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .appleShadow()
                .offset(y: 35)
                .zIndex(1000)
            }
        }
        .onAppear {
            if isInitialLoad {
                Task {
                    isInitialLoad = false
                    await loadCurrentContentType()
                }
            }
        }
        .onChange(of: selectedContentType) { _ in
            Task {
                await loadCurrentContentType()
            }
        }
    }
    
    private func loadCurrentContentType() async {
        switch selectedContentType {
        case .chats:
            print("TaskListView: Loading chat sessions...")
            do {
                try await chatSessionManager.loadSessions(refresh: true)
                print("TaskListView: Loaded sessions successfully")
            } catch {
                print("TaskListView: Error loading sessions: \(error)")
            }
        case .tasks:
            print("TaskListView: Loading tasks...")
            do {
                try await taskManager.listTasks(refresh: true)
                print("TaskListView: Listed tasks successfully")
            } catch {
                print("TaskListView: Error loading tasks: \(error)")
            }
        case .containers:
            print("TaskListView: Containers not yet implemented")
        }
    }
}

// MARK: - Enhanced Session Row
struct EnhancedSessionRow: View {
    let session: SessionListItem
    let sessionManager: ChatSessionManager
    let onSelect: () -> Void
    
    @State private var sessionTitle: String = ""
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 16) {
                // Left: Session Title
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionTitle.isEmpty ? "Loading..." : sessionTitle)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(Color.textPrimary(for: colorScheme))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(sessionTitle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Removed: Message count metadata per user request
                
                // Right: Status + Chevron
                HStack(spacing: 12) {
                    let statusInfo = sessionManager.mapSessionStatus(session)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusInfo.color)
                            .frame(width: 6, height: 6)
                        
                        Text(statusInfo.text)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(statusInfo.color)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.textSecondary(for: colorScheme))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16) // rounded-xl for more square-rounded look
                    .fill(
                        .regularMaterial.opacity(0.7)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.glassmorphicBackground(for: colorScheme))
                    )
                    // Removed: Border stroke per user request for cleaner look
            )
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 20,
                x: 0,
                y: 8
            )
            .shadow(
                color: Color.black.opacity(0.04),
                radius: 10,
                x: 0,
                y: -6
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.3), value: isHovered)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.3)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onAppear {
            Task {
                sessionTitle = await sessionManager.getSessionTitle(for: session)
            }
        }
    }
}


// MARK: - Content List View
struct ContentListView: View {
    let contentType: ContentType
    let chatSessionManager: ChatSessionManager
    let taskManager: TaskManager
    let onTaskSelect: (AriaTask) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            switch contentType {
            case .chats:
                ChatSessionListView(
                    sessionManager: chatSessionManager,
                    onTaskSelect: onTaskSelect
                )
            case .tasks:
                TaskListContentView(
                    taskManager: taskManager,
                    onTaskSelect: onTaskSelect
                )
            case .containers:
                ContainerListView()
            }
        }
    }
}

// MARK: - Chat Session List View
struct ChatSessionListView: View {
    let sessionManager: ChatSessionManager
    let onTaskSelect: (AriaTask) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if sessionManager.sessions.isEmpty && !sessionManager.isLoadingSessions {
                Text("No chat sessions available")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary(for: colorScheme))
                    .padding(.vertical, 20)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(sessionManager.sessions, id: \.id) { session in
                            EnhancedSessionRow(
                                session: session,
                                sessionManager: sessionManager,
                                onSelect: {
                                    // Convert session to AriaTask for compatibility
                                    let task = AriaTask(
                                        id: session.id,
                                        title: session.title ?? "Chat Session",
                                        detailIdentifier: session.id,
                                        status: mapSessionStatusToTaskStatus(session.status),
                                        timestamp: session.createdAtDate ?? Date()
                                    )
                                    onTaskSelect(task)
                                }
                            )
                        }
                        
                        if sessionManager.hasMoreSessions && !sessionManager.isLoadingSessions {
                            Button(action: {
                                Task {
                                    try? await sessionManager.loadMoreSessions()
                                }
                            }) {
                                Text("Load More")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.buttonText(for: colorScheme))
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
            
            if let error = sessionManager.sessionError {
                Text("Error: \(error.localizedDescription)")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
    }
    
    private func mapSessionStatusToTaskStatus(_ status: String) -> TaskStatus {
        switch status.lowercased() {
        case "active":
            return .completed
        case "completed":
            return .completed
        case "failed":
            return .failed
        default:
            return .pending
        }
    }
}

// MARK: - Task List Content View
struct TaskListContentView: View {
    let taskManager: TaskManager
    let onTaskSelect: (AriaTask) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if taskManager.tasks.isEmpty && !taskManager.isLoadingTasks {
                Text("No tasks available")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary(for: colorScheme))
                    .padding(.vertical, 20)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(taskManager.tasks, id: \.id) { taskResponse in
                            let ariaTask = convertTaskResponseToAriaTask(taskResponse)
                            TaskRow(
                                task: ariaTask,
                                onSelect: { onTaskSelect(ariaTask) }
                            )
                        }
                        
                        if taskManager.hasMoreTasks && !taskManager.isLoadingTasks {
                            Button(action: {
                                Task {
                                    try? await taskManager.loadMoreTasks()
                                }
                            }) {
                                Text("Load More")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.buttonText(for: colorScheme))
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
            
            if let error = taskManager.taskError {
                Text("Error: \(error.localizedDescription)")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
    }
    
    private func convertTaskResponseToAriaTask(_ taskResponse: TaskResponse) -> AriaTask {
        let title = generateTaskTitle(from: taskResponse)
        
        return AriaTask(
            id: taskResponse.id,
            title: title,
            detailIdentifier: taskResponse.sessionId ?? "",
            status: mapTaskStatusLocally(taskResponse.status),
            timestamp: taskResponse.createdAt
        )
    }
    
    private func mapTaskStatusLocally(_ status: String) -> TaskStatus {
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
    
    private func generateTaskTitle(from taskResponse: TaskResponse) -> String {
        let taskType = taskResponse.type
        let payload = taskResponse.payload
        
        switch taskType.lowercased() {
        case "analysis":
            if let args = payload?.args,
               let dataset = args["dataset"]?.wrappedValue as? String {
                return "Analysis: \(dataset)"
            }
            return "Data Analysis Task"
            
        case "processing":
            if let args = payload?.args,
               let batchSize = args["batch_size"]?.wrappedValue as? Int {
                return "Processing: Batch size \(batchSize)"
            }
            return "Processing Task"
            
        case "shell", "command":
            if let command = payload?.command {
                return "Shell: \(command.prefix(30))\(command.count > 30 ? "..." : "")"
            }
            return "Shell Command"
            
        default:
            return "\(taskType.capitalized) Task"
        }
    }
}

// MARK: - Container List View
struct ContainerListView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.box")
                .font(.system(size: 48))
                .foregroundColor(Color.textTertiary(for: colorScheme))
            
            VStack(spacing: 8) {
                Text("Containers")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.textTertiary(for: colorScheme))
                
                Text("Container management will be available in a future update")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textTertiary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
    }
}
    
    private func convertTaskResponseToAriaTask(_ taskResponse: TaskResponse) -> AriaTask {
        // Generate a meaningful title from task metadata
        let title = generateTaskTitle(from: taskResponse)
        
        return AriaTask(
            id: taskResponse.id,
            title: title,
            detailIdentifier: taskResponse.sessionId ?? "",
            status: mapTaskStatusLocally(taskResponse.status),
            timestamp: taskResponse.createdAt
        )
    }
    
    private func mapTaskStatusLocally(_ status: String) -> TaskStatus {
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
    
    private func generateTaskTitle(from taskResponse: TaskResponse) -> String {
        // Try to extract meaningful information from task type and payload
        let taskType = taskResponse.type
        let payload = taskResponse.payload
        
        // Handle specific task types
        switch taskType.lowercased() {
        case "shell", "command":
            if let command = payload?.command {
                return "Run: \(command.prefix(30))\(command.count > 30 ? "..." : "")"
            }
            return "Shell Command"
            
        case "file", "read_file":
            if let args = payload?.args,
               let filename = args["file"]?.wrappedValue as? String {
                return "Read: \(URL(fileURLWithPath: filename).lastPathComponent)"
            }
            return "File Operation"
            
        case "write", "write_file":
            if let args = payload?.args,
               let filename = args["file"]?.wrappedValue as? String {
                return "Write: \(URL(fileURLWithPath: filename).lastPathComponent)"
            }
            return "File Write"
            
        case "search", "grep":
            if let args = payload?.args,
               let pattern = args["pattern"]?.wrappedValue as? String {
                return "Search: \(pattern.prefix(20))\(pattern.count > 20 ? "..." : "")"
            }
            return "Search Operation"
            
        case "api", "http", "request":
            if let args = payload?.args,
               let url = args["url"]?.wrappedValue as? String {
                let domain = URL(string: url)?.host ?? url
                return "API: \(domain.prefix(25))\(domain.count > 25 ? "..." : "")"
            }
            return "API Request"
            
        case "analysis", "analyze":
            return "Analysis Task"
            
        case "generation", "generate":
            return "Generation Task"
            
        case "chat_session":
            if let args = payload?.args,
               let description = args["session_description"]?.wrappedValue as? String {
                return description
            }
            return "Chat Session"
            
        default:
            // Extract first meaningful argument value
            if let args = payload?.args,
               let firstValue = args.values.first?.wrappedValue as? String,
               !firstValue.isEmpty {
                let cleanValue = firstValue.replacingOccurrences(of: "\n", with: " ")
                return "\(taskType.capitalized): \(cleanValue.prefix(25))\(cleanValue.count > 25 ? "..." : "")"
            }
            
            // Fall back to type-based title
            return "\(taskType.capitalized) Task"
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

// MARK: - Session Row
struct SessionRow: View {
    let task: AriaTask
    let onSelect: () -> Void
    
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    var sessionStatusColor: Color {
        switch task.status {
        case .running:
            return Color(hue: 60/360, saturation: 0.85, brightness: 0.95) // Yellow - Responding
        case .completed, .inProgress:
            return Color(hue: 120/360, saturation: 0.85, brightness: 0.85) // Green - Active  
        case .failed:
            return Color(hue: 0/360, saturation: 0.85, brightness: 0.85) // Red - Disconnected
        case .pending, .paused:
            return Color(hue: 120/360, saturation: 0.85, brightness: 0.85) // Green - Default to Active
        }
    }
    
    var sessionStatusText: String {
        switch task.status {
        case .running:
            return "Responding"
        case .failed:
            return "Disconnected"
        case .completed, .inProgress, .pending, .paused:
            return "Active"
        }
    }
    
    var sessionTitle: String {
        // For now, use existing title - will be enhanced in Phase 2
        if task.title.contains("Chat Session") || task.title.contains("new chat session") {
            return "New chat session" // Temporary fallback
        }
        return task.title
    }
    
    var sessionMetadata: (messageCount: String, lastAccessed: String) {
        // Mock data for now - will be enhanced in Phase 4
        return ("3 messages", "2m ago")
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 16) {
                // Left: Session Title
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionTitle)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(Color.textPrimary(for: colorScheme))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(sessionTitle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Removed: Message count metadata per user request
                
                // Right: Status + Chevron
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(sessionStatusColor)
                            .frame(width: 6, height: 6)
                        
                        Text(sessionStatusText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(sessionStatusColor)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.textSecondary(for: colorScheme))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16) // rounded-xl for more square-rounded look
                    .fill(
                        .regularMaterial.opacity(0.7)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.glassmorphicBackground(for: colorScheme))
                    )
                    // Removed: Border stroke per user request for cleaner look
            )
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 20,
                x: 0,
                y: 8
            )
            .shadow(
                color: Color.black.opacity(0.04),
                radius: 10,
                x: 0,
                y: -6
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.3), value: isHovered)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.3)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Metadata Badge
struct MetadataBadge: View {
    let text: String
    let icon: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(Color.textSecondary(for: colorScheme))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8) // rounded-lg per design system
                .fill(Color.glassmorphicBackground(for: colorScheme))
                .shadow(
                    color: Color.white.opacity(0.1),
                    radius: 1,
                    x: 0,
                    y: 1
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 1,
                    x: 0,
                    y: -1
                )
        )
    }
}

// MARK: - Logging View
struct LoggingView: View {
    @State private var selectedTimeframe = "7d"
    @State private var isTimeframeMenuOpen = false
    @StateObject private var observabilityService = ObservabilityService.shared
    @Environment(\.colorScheme) var colorScheme
    
    let timeframeOptions = [
        ("24h", "Last 24 hours"),
        ("today", "Today"),
        ("7d", "Last 7 days"),
        ("30d", "Last 30 days"),
        ("all", "All time")
    ]
    
    var activeTimeframeLabel: String {
        timeframeOptions.first { $0.0 == selectedTimeframe }?.1 ?? "Last 7 days"
    }
    
    var filteredLogs: [LogEntry] {
        observabilityService.logs
    }
    
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
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if observabilityService.isLoadingLogs {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading logs...")
                                    .font(.textSM)
                                    .foregroundColor(Color.textSecondary(for: colorScheme))
                            }
                            .padding(.vertical, 20)
                        } else if let error = observabilityService.logsError {
                            Text("Error loading logs: \(error.localizedDescription)")
                                .font(.textSM)
                                .foregroundColor(.red)
                                .padding(.vertical, 20)
                        } else if filteredLogs.isEmpty {
                            Text("No logs available")
                                .font(.textSM)
                                .foregroundColor(Color.textSecondary(for: colorScheme))
                                .padding(.vertical, 20)
                        } else {
                            ForEach(filteredLogs, id: \.id) { entry in
                                RealTimeLogEntryRow(entry: entry)
                                Divider()
                            }
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
        .onAppear {
            Task {
                do {
                    try await observabilityService.loadRecentLogs(limit: 100)
                    // Start real-time log streaming
                    observabilityService.startLogStreaming()
                } catch {
                    print("LoggingView: Error loading logs: \(error)")
                }
            }
        }
        .onDisappear {
            observabilityService.stopLogStreaming()
        }
    }
}

struct LocalLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: String
    let source: String
    let message: String
    var details: [String: Any]? = nil
}

struct LogEntryRow: View {
    let entry: LocalLogEntry
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

// MARK: - Real-time Log Entry Row for API LogEntry
struct RealTimeLogEntryRow: View {
    let entry: LogEntry
    @State private var isExpanded = false
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    var levelColor: Color {
        switch entry.level.lowercased() {
        case "error": return .red
        case "warn", "warning": return .orange
        case "info": return .blue
        case "debug": return .gray
        default: return Color.textPrimary(for: colorScheme)
        }
    }
    
    var formattedTimestamp: String {
        guard let date = entry.timestampDate else {
            return entry.timestamp
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Timestamp
                Text(formattedTimestamp)
                    .frame(width: 120, alignment: .leading)
                    .font(.monoXS)
                
                // Level
                Text(entry.level.uppercased())
                    .frame(width: 60, alignment: .leading)
                    .font(.textXS)
                    .foregroundColor(levelColor)
                
                // Component (instead of source)
                Text(entry.metadata.component)
                    .frame(width: 80, alignment: .leading)
                    .font(.textXS)
                
                // Message
                Text(entry.message)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.textXS)
                    .lineLimit(1)
                
                // Expand chevron if metadata has details
                if !entry.fields.isEmpty || entry.metadata.operation != nil {
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
                if !entry.fields.isEmpty || entry.metadata.operation != nil {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            }
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Metadata details
                    if let operation = entry.metadata.operation {
                        HStack {
                            Text("Operation:")
                                .font(.textXS(.medium))
                            Text(operation)
                                .font(.textXS)
                        }
                    }
                    
                    if let durationMs = entry.metadata.durationMs {
                        HStack {
                            Text("Duration:")
                                .font(.textXS(.medium))
                            Text("\(durationMs)ms")
                                .font(.textXS)
                        }
                    }
                    
                    if let sessionId = entry.sessionId {
                        HStack {
                            Text("Session:")
                                .font(.textXS(.medium))
                            Text(sessionId.prefix(8))
                                .font(.monoXS)
                        }
                    }
                    
                    // Additional fields
                    if !entry.fields.isEmpty {
                        Text("Additional Data:")
                            .font(.textXS(.medium))
                            .padding(.top, 4)
                        
                        ForEach(Array(entry.fields.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text("\(key):")
                                    .font(.textXS(.medium))
                                Text("\(entry.fields[key]?.wrappedValue ?? "nil")")
                                    .font(.monoXS)
                            }
                        }
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
    let aiSteps: [EnhancedStep]
    
    @State private var viewMode: ViewMode = .richText
    @State private var expandedSections = Set<String>()
    @Environment(\.colorScheme) var colorScheme
    
    enum ViewMode {
        case richText
        case json
    }
    
    var detailContent: StepDetailsContent? {
        getStepDetailsContent(for: step, tasks: tasks, aiSteps: aiSteps)
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
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Accordion sections - reordered: Input → Output → Summary
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
                            title: content.isAiStep ? "Output" : "Additional Info",
                            content: content.output,
                            viewMode: $viewMode,
                            isExpanded: expandedSections.contains("output")
                        ) {
                            toggleSection("output")
                        }
                        
                        Divider()
                        
                        AccordionSection(
                            title: content.isAiStep ? "Summary" : "Progress & Status",
                            content: content.thinking,
                            viewMode: $viewMode,
                            isExpanded: expandedSections.contains("thinking")
                        ) {
                            toggleSection("thinking")
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
            // Default expand output section
            expandedSections.insert("output")
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
        // Create a safe copy of jsonData with only JSON-serializable types
        let safeJsonData = jsonData.compactMapValues { value -> Any? in
            // Convert non-JSON-serializable types to strings
            switch value {
            case let stringValue as String:
                return stringValue
            case let intValue as Int:
                return intValue
            case let doubleValue as Double:
                return doubleValue
            case let boolValue as Bool:
                return boolValue
            case let arrayValue as [Any]:
                return arrayValue
            case let dictValue as [String: Any]:
                return dictValue
            default:
                // Convert any other type to string representation
                return String(describing: value)
            }
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: safeJsonData, options: .prettyPrinted),
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
func getStepDetailsContent(for step: EnhancedStep, tasks: [AriaTask], aiSteps: [EnhancedStep]) -> StepDetailsContent? {
    
    // Find the user input that triggered this response
    func findUserInput() -> String {
        if let stepIndex = aiSteps.firstIndex(where: { $0.id == step.id }) {
            // Look backwards for the last user message
            for i in stride(from: stepIndex, through: 0, by: -1) {
                if aiSteps[i].type == .userMessage {
                    return aiSteps[i].text
                }
            }
        }
        return "No user input found"
    }
    
    // Generate summary from thinking steps, execution context, or metadata
    func generateSummary() -> (text: String, json: [String: Any]) {
        var summaryText = "No processing information available"
        var summaryJson: [String: Any] = [:]
        
        // Prioritize reasoning field from metadata if available
        if let metadata = step.metadata, let reasoning = metadata.reasoning {
            summaryText = reasoning
            summaryJson = ["reasoning": reasoning]
        } else if let thinkingSteps = step.thinkingSteps, !thinkingSteps.isEmpty {
            summaryText = "Thinking Steps:\n"
            var stepsArray: [[String: Any]] = []
            
            for thinking in thinkingSteps {
                let confidenceText = thinking.confidence != nil ? String(format: " (%.1f%% confidence)", thinking.confidence! * 100) : ""
                summaryText += "\n\(thinking.step). \(thinking.type): \(thinking.content)\(confidenceText)"
                
                var stepData: [String: Any] = [
                    "step": thinking.step,
                    "type": thinking.type,
                    "content": thinking.content
                ]
                if let confidence = thinking.confidence {
                    stepData["confidence"] = confidence
                }
                stepsArray.append(stepData)
            }
            summaryJson["thinking_steps"] = stepsArray
        }
        
        // Add execution context if available (and not already handled by reasoning)
        if let context = step.executionContext {
            // Only add execution context if we don't already have reasoning
            if step.metadata?.reasoning == nil {
                summaryText += "\n\nExecution Context:"
                if let duration = context.duration_ms {
                    summaryText += "\n  Duration: \(duration)ms"
                }
                if let memory = context.memory_used {
                    summaryText += "\n  Memory Used: \(memory)"
                }
                if let tokens = context.tokens_consumed {
                    summaryText += "\n  Tokens: \(tokens)"
                }
            }
            
            var contextData: [String: Any] = [:]
            if let duration = context.duration_ms { contextData["duration_ms"] = duration }
            if let memory = context.memory_used { contextData["memory_used"] = memory }
            if let tokens = context.tokens_consumed { contextData["tokens_consumed"] = tokens }
            if let cpu = context.cpu_percent { contextData["cpu_percent"] = cpu }
            if let validation = context.inputValidation { contextData["inputValidation"] = validation }
            
            if !contextData.isEmpty {
                summaryJson["execution_context"] = contextData
            }
        }
        
        if summaryText == "No processing information available" {
            summaryText = "Step Status: \(step.status.rawValue)"
            summaryJson = ["status": step.status.rawValue, "type": String(describing: step.type)]
        }
        
        return (summaryText, summaryJson)
    }
    
    // Handle special task details
    if step.text.hasPrefix("TASK_DETAIL_") {
        let taskId = step.text.replacingOccurrences(of: "TASK_DETAIL_", with: "")
        if let task = tasks.first(where: { $0.id == taskId }) {
            return StepDetailsContent(
                input: SectionContent(
                    richText: "Task: \(task.title)",
                    jsonData: ["title": task.title, "id": task.id]
                ),
                thinking: SectionContent(
                    richText: "Task Status: \(task.status.rawValue)\nCreated: \(task.timestamp)",
                    jsonData: ["status": task.status.rawValue, "timestamp": task.timestamp]
                ),
                output: SectionContent(
                    richText: "Task ID: \(task.id)\nDetail Identifier: \(task.detailIdentifier)",
                    jsonData: ["id": task.id, "detailIdentifier": task.detailIdentifier]
                ),
                taskStatus: task.status.rawValue,
                isAiStep: false
            )
        }
    }
    
    // Handle tool steps
    if step.type == .tool {
        let userInput = findUserInput()
        let summary = generateSummary()
        
        var outputText = "Tool execution "
        var outputJson: [String: Any] = [:]
        
        if step.status == .failed {
            outputText += "failed"
            if let error = step.errorMessage {
                outputText += "\nError: \(error)"
                outputJson["error"] = error
            }
        } else if let result = step.toolResult {
            outputText = result
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
                richText: userInput,
                jsonData: ["userInput": userInput]
            ),
            thinking: SectionContent(
                richText: summary.text,
                jsonData: summary.json
            ),
            output: SectionContent(
                richText: outputText,
                jsonData: outputJson
            ),
            taskStatus: nil,
            isAiStep: true
        )
    }
    
    // Handle AI responses and other steps
    let userInput = findUserInput()
    let summary = generateSummary()
    
    return StepDetailsContent(
        input: SectionContent(
            richText: userInput,
            jsonData: ["userInput": userInput]
        ),
        thinking: SectionContent(
            richText: summary.text,
            jsonData: summary.json
        ),
        output: SectionContent(
            richText: step.text,
            jsonData: ["response": step.text, "stepId": step.id]
        ),
        taskStatus: nil,
        isAiStep: true
    )
}