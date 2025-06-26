import SwiftUI
import AriaChatFeature

@main
struct AriaChatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene - we create the window manually in AppDelegate
        Settings {
            EmptyView()
        }
    }
}

// ContentView and WindowAccessor are no longer needed
// Window is created directly in AppDelegate
