import SwiftUI
import Combine

// Global blur settings matching React's blur-context.tsx
public final class BlurSettings: ObservableObject {
    public static let shared = BlurSettings()
    
    @Published public var blurIntensity: CGFloat = 16.0 // Default blur intensity matching React
    
    private init() {}
}

// Extension to suppress concurrency warnings for legacy code
extension BlurSettings: @unchecked Sendable {}

// Theme settings for the app
public final class ThemeSettings: ObservableObject {
    public static let shared = ThemeSettings()
    
    @Published public var selectedTheme: String = "System" {
        didSet {
            UserDefaults.standard.set(selectedTheme, forKey: "selectedTheme")
        }
    }
    
    public var colorScheme: ColorScheme? {
        switch selectedTheme {
        case "Light":
            return .light
        case "Dark":
            return .dark
        default: // System
            return nil
        }
    }
    
    private init() {
        // Load saved theme
        if let saved = UserDefaults.standard.string(forKey: "selectedTheme") {
            selectedTheme = saved
        }
    }
}

extension ThemeSettings: @unchecked Sendable {}