import SwiftUI

public struct ContentView: View {
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
            
            // Floating glassmorphic chatbar
            GlassmorphicChatbar()
                .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WindowBackgroundView())
        .onAppear {
            print("ContentView appeared")
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
