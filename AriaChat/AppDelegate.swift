import Cocoa
import SwiftUI
import AriaChatFeature

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
        // Initialize authentication on app launch
        Task {
            await AuthenticationManager.shared.initialize()
        }
        
        // Register URL scheme with system
        URLSchemeHandler.shared.registerURLScheme()
        
        // Register URL scheme handler
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
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
        
        // Create SwiftUI content with conditional rendering
        let contentView = AriaRootView()
            .frame(width: 2000, height: 1200)
            .environmentObject(BlurSettings.shared)
            .environmentObject(ThemeSettings.shared)
            .environmentObject(AuthenticationManager.shared)
            .preferredColorScheme(ThemeSettings.shared.colorScheme)
        
        // Set content
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - URL Scheme Handler
    
    @MainActor @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else {
            print("AppDelegate: Invalid URL received")
            return
        }
        
        // Delegate to URL scheme handler
        URLSchemeHandler.shared.handleURL(url)
    }
}