import Cocoa
import SwiftUI
import AriaChatFeature

// Reactive theme wrapper that updates color scheme when theme changes
struct ReactiveThemeWrapper<Content: View>: View {
    @EnvironmentObject var themeSettings: ThemeSettings
    let content: Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .preferredColorScheme(themeSettings.colorScheme)
    }
}

class CustomFloatingWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        // Return the frame rect without any constraints
        // This allows the window to be positioned anywhere on screen
        return frameRect
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: CustomFloatingWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create custom window with large canvas size
        let contentRect = NSRect(x: 0, y: 0, width: 2000, height: 1200)
        
        window = CustomFloatingWindow(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window for free movement
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isMovableByWindowBackground = true
        window.level = .popUpMenu // Higher level allows positioning above menu bar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Hide window buttons
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Create SwiftUI content
        let contentView = ReactiveThemeWrapper {
            ZStack {
                // Large transparent canvas for complete freedom
                Color.clear
                    .frame(width: 2000, height: 1200)
                
                // Chatbar positioned in center
                GlassmorphicChatbar()
            }
            .frame(width: 2000, height: 1200)
        }
        .environmentObject(BlurSettings.shared)
        .environmentObject(ThemeSettings.shared)
        
        // Set content
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}