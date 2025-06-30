import SwiftUI

/// Centralized provider for status icons across the application
enum StatusIconProvider {
    
    /// Configuration for status icons
    struct IconConfig {
        let systemName: String
        let color: Color
        let size: CGFloat
        let weight: Font.Weight
        
        init(systemName: String, color: Color, size: CGFloat = 14, weight: Font.Weight = .regular) {
            self.systemName = systemName
            self.color = color
            self.size = size
            self.weight = weight
        }
    }
    
    /// Returns the appropriate icon configuration for a given step
    static func iconConfig(for step: EnhancedStep, colorScheme: ColorScheme) -> IconConfig? {
        switch step.type {
        case .tool:
            return toolIcon(for: step, colorScheme: colorScheme)
        case .thought:
            return thoughtIcon(for: step, colorScheme: colorScheme)
        case .response:
            return responseIcon(for: step, colorScheme: colorScheme)
        case .userMessage:
            return nil // User messages don't have icons
        }
    }
    
    /// Icon configuration for tool steps
    private static func toolIcon(for step: EnhancedStep, colorScheme: ColorScheme) -> IconConfig {
        switch step.status {
        case .completed:
            // Checkmark for completed tools
            return IconConfig(
                systemName: "checkmark",
                color: Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.9),
                size: 16
            )
        case .failed:
            // Error icon for failed tools
            return IconConfig(
                systemName: "exclamationmark.triangle.fill",
                color: Color(red: 239/255, green: 68/255, blue: 68/255),
                size: 14
            )
        case .active:
            // Bolt icon for active tools
            let color = colorScheme == .dark ? Color.white : Color.black.opacity(0.8)
            return IconConfig(
                systemName: "bolt.fill",
                color: color,
                size: 14
            )
        }
    }
    
    /// Icon configuration for thought steps
    private static func thoughtIcon(for step: EnhancedStep, colorScheme: ColorScheme) -> IconConfig? {
        let lowerText = step.text.lowercased()
        
        switch step.status {
        case .failed:
            return IconConfig(
                systemName: "exclamationmark.triangle.fill",
                color: Color(red: 239/255, green: 68/255, blue: 68/255),
                size: 14
            )
        case .active:
            // Show loader for processing thoughts
            if lowerText.contains("synthesizing") || lowerText.contains("processing") {
                return nil // Return nil to show ProgressView in the view
            }
            // Default dot for other active thoughts
            return nil // Return nil to show Circle in the view
        case .completed:
            // No icon for completed thoughts
            return nil
        }
    }
    
    /// Icon configuration for response steps
    private static func responseIcon(for step: EnhancedStep, colorScheme: ColorScheme) -> IconConfig? {
        switch step.status {
        case .failed:
            return IconConfig(
                systemName: "exclamationmark.triangle.fill",
                color: Color(red: 239/255, green: 68/255, blue: 68/255),
                size: 14
            )
        case .active, .completed:
            // No icon for active or completed responses
            return nil
        }
    }
    
    /// Returns if a progress indicator should be shown instead of an icon
    static func shouldShowProgressIndicator(for step: EnhancedStep) -> Bool {
        if step.type == .thought && step.status == .active {
            let lowerText = step.text.lowercased()
            return lowerText.contains("synthesizing") || lowerText.contains("processing")
        }
        return false
    }
    
    /// Returns if a simple dot should be shown instead of an icon
    static func shouldShowDot(for step: EnhancedStep) -> Bool {
        return step.type == .thought && step.status == .active && !shouldShowProgressIndicator(for: step)
    }
}