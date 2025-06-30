import Foundation

/// Utility for filtering message visibility in different UI contexts
enum MessageFilterUtils {
    
    /// Determines if a step should be visible in the main chat window
    /// Delegates to MessageVisibilityRules for deterministic behavior
    static func isVisibleInMainChat(_ step: EnhancedStep) -> Bool {
        return MessageVisibilityRules.isVisibleInMainChat(step)
    }
    
    /// All steps are visible in the details pane
    static func isVisibleInDetailsPane(_ step: EnhancedStep) -> Bool {
        return true
    }
    
    /// Categories for organizing messages in the side pane
    enum MessageCategory {
        case status
        case execution
        case tools
        case thinking
        case progress
        case summary
        case intermediate
        case other
        
        var label: String {
            switch self {
            case .status: return "Status Update"
            case .execution: return "Task Execution"
            case .tools: return "Tool Usage"
            case .thinking: return "Reasoning"
            case .progress: return "Progress"
            case .summary: return "Summary"
            case .intermediate: return "Intermediate Response"
            case .other: return "Other"
            }
        }
    }
    
    /// Categorizes a message for display in the side pane
    static func categorizeForSidePane(_ step: EnhancedStep) -> MessageCategory {
        // No metadata - default categorization
        guard let metadata = step.metadata else {
            if step.type == .thought {
                return .thinking
            }
            return .other
        }
        
        // Status messages
        if metadata.isStatus {
            switch metadata.messageType {
            case "status":
                if step.text.contains("Executing task:") {
                    return .execution
                }
                if step.text.contains("Executed tool") {
                    return .tools
                }
                return .status
            case "thinking":
                return .thinking
            default:
                return .status
            }
        }
        
        // Synthesis/Summary
        if metadata.messageType == "synthesis" {
            return .summary
        }
        
        // Progress updates
        if metadata.messageType == "progress" {
            return .progress
        }
        
        // Non-final responses (shouldn't happen, but just in case)
        if metadata.messageType == "response" && !metadata.isFinal {
            return .intermediate
        }
        
        return .other
    }
}