import SwiftUI

public struct ContentView: View {
    @State private var connectionStatus = "Not connected"
    @State private var sessionId = ""
    @State private var showDebug = true
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Subtle background for debugging
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor).opacity(0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Debug controls at top
                if showDebug {
                    VStack(spacing: 10) {
                        Text("Debug Controls")
                            .font(.headline)
                        
                        Text("Status: \(connectionStatus)")
                            .font(.caption)
                        
                        if !sessionId.isEmpty {
                            Text("Session: \(sessionId)")
                                .font(.caption)
                        }
                        
                        HStack {
                            Button("Test Connection") {
                                Task {
                                    await testConnection()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Create Session") {
                                Task {
                                    await createSession()
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("List Tasks") {
                                Task {
                                    await listTasks()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button("Hide Debug") {
                            showDebug = false
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Floating glassmorphic chatbar
                GlassmorphicChatbar()
                    .padding(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WindowBackgroundView())
        .onAppear {
            print("ContentView appeared")
        }
    }
    
    @MainActor
    private func testConnection() async {
        connectionStatus = "Connecting..."
        do {
            print("DEBUG: Testing connection...")
            let connectionManager = await GRPCConnectionManager.shared
            try await connectionManager.connect()
            connectionStatus = "Connected to gRPC"
            print("DEBUG: Connection successful")
        } catch {
            connectionStatus = "Failed: \(error.localizedDescription)"
            print("DEBUG: Connection failed: \(error)")
        }
    }
    
    @MainActor
    private func createSession() async {
        do {
            print("DEBUG: Creating session...")
            let sessionManager = SessionManager.shared
            let id = try await sessionManager.createSession()
            sessionId = id
            connectionStatus = "Session created!"
            print("DEBUG: Session created: \(id)")
        } catch {
            connectionStatus = "Session error: \(error)"
            print("DEBUG: Session error: \(error)")
        }
    }
    
    @MainActor
    private func listTasks() async {
        do {
            print("DEBUG: Listing tasks...")
            let taskManager = TaskManager.shared
            try await taskManager.listTasks(sessionId: sessionId.isEmpty ? nil : sessionId, refresh: true)
            connectionStatus = "Listed \(taskManager.tasks.count) tasks"
            print("DEBUG: Found \(taskManager.tasks.count) tasks")
        } catch {
            connectionStatus = "Task error: \(error)"
            print("DEBUG: Task error: \(error)")
        }
    }
}

// Makes the window background transparent
struct WindowBackgroundView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.styleMask.insert(.fullSizeContentView)
                window.isMovableByWindowBackground = true
                window.hasShadow = false
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
