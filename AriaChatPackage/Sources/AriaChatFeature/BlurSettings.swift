import SwiftUI
import Combine
import AppKit

// Global blur settings matching React's blur-context.tsx
public final class BlurSettings: ObservableObject {
    public static let shared = BlurSettings()
    
    @Published public var blurIntensity: CGFloat = 16.0 // Default blur intensity (0 = transparent, 40 = opaque)
    
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
    
    @Published public var systemAppearance: NSAppearance.Name = .aqua
    
    public var colorScheme: ColorScheme? {
        switch selectedTheme {
        case "Light":
            return .light
        case "Dark":
            return .dark
        default: // System
            // When System is selected, follow the actual system appearance
            return systemAppearance == .darkAqua ? .dark : .light
        }
    }
    
    private init() {
        // Load saved theme
        if let saved = UserDefaults.standard.string(forKey: "selectedTheme") {
            selectedTheme = saved
        }
        
        // Set initial system appearance
        updateSystemAppearance()
        
        // Listen for system appearance changes
        DistributedNotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateSystemAppearance()
        }
    }
    
    deinit {
        DistributedNotificationCenter.default.removeObserver(self)
    }
    
    private func updateSystemAppearance() {
        DispatchQueue.main.async {
            if let appearance = NSApplication.shared.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
                self.systemAppearance = appearance
            }
        }
    }
}

extension ThemeSettings: @unchecked Sendable {}