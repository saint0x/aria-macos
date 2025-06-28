import Foundation

/// Utility for filtering message visibility in different UI contexts
enum MessageFilterUtils {
    
    /// Determines if a step should be visible in the main chat window
    /// Uses metadata when available for semantic filtering
    static func isVisibleInMainChat(_ step: EnhancedStep) -> Bool {
        // If we have metadata, use it for semantic filtering
        if let metadata = step.metadata {
            // Hide status messages
            if metadata.isStatus {
                return false
            }
            // Show final messages
            if metadata.isFinal {
                return true
            }
        }
        
        // Fall back to type-based filtering
        switch step.type {
        case .response:
            // Show responses (final messages or those without metadata)
            return true
        case .tool:
            // Only show indented tool calls
            return step.isIndented
        case .userMessage:
            // Always show user messages
            return true
        case .thought:
            // Hide thoughts from main chat
            return false
        }
    }
    
    /// All steps are visible in the details pane
    static func isVisibleInDetailsPane(_ step: EnhancedStep) -> Bool {
        return true
    }
}