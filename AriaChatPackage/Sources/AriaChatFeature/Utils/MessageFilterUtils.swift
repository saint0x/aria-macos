import Foundation

/// Utility for filtering message visibility in different UI contexts
enum MessageFilterUtils {
    
    /// Determines if a step should be visible in the main chat window
    /// Following the new message handling rules:
    /// - Show: User messages, response types, and messages with metadata.is_final == true
    /// - Hide: Status messages and intermediate thoughts
    static func isVisibleInMainChat(_ step: EnhancedStep) -> Bool {
        // User messages are always visible
        if step.type == .userMessage {
            return true
        }
        
        // Response type steps need careful filtering
        if step.type == .response {
            let lowerText = step.text.lowercased()
            
            // Hide messages that look like JSON or debug output
            if step.text.contains("{") && step.text.contains("}") && 
               (step.text.contains("tool_name") || step.text.contains("parameters") || 
                step.text.contains("message_metadata") || step.text.contains("message_type")) {
                return false
            }
            
            // Hide if it's an executing task message
            if step.text.hasPrefix("Executing task:") || step.text.contains("Executing task:") {
                return false
            }
            
            // Hide "Executed tool" messages
            if step.text.contains("Executed tool") && step.text.contains("successfully") {
                return false
            }
            
            // Hide summary messages - more comprehensive patterns
            let summaryPatterns = [
                "initiated", "performed", "executed", "search was conducted",
                "based on the user's request", "providing a selection",
                "the assistant", "i've", "we've", "has been", "have been",
                "was completed", "were completed", "successfully completed",
                "carried out", "undertaken", "accomplished",
                "the following", "here's what", "to summarize",
                "in summary", "overall", "in conclusion"
            ]
            
            if summaryPatterns.contains(where: { lowerText.contains($0) }) {
                return false
            }
            
            // Show acknowledgments (they're response type with acknowledgment messageType)
            if let metadata = step.metadata, metadata.messageType == "acknowledgment" {
                return true
            }
            
            return true
        }
        
        // Tool calls are visible when indented, but hide raw JSON responses
        if step.type == .tool && step.isIndented {
            // Hide if the tool result contains raw JSON
            if let result = step.toolResult {
                let trimmedResult = result.trimmingCharacters(in: .whitespacesAndNewlines)
                if (trimmedResult.hasPrefix("{") && trimmedResult.hasSuffix("}")) ||
                   (trimmedResult.hasPrefix("[") && trimmedResult.hasSuffix("]")) {
                    return false
                }
            }
            return true
        }
        
        // For other message types, check metadata
        if let metadata = step.metadata {
            let lowerText = step.text.lowercased()
            
            // Hide synthesis/summary messages
            if metadata.messageType == "synthesis" || metadata.messageType == "summary" {
                return false
            }
            // Hide status messages
            if metadata.isStatus {
                return false
            }
            
            // Hide messages that look like JSON or debug output
            if step.text.contains("{") && step.text.contains("}") && 
               (step.text.contains("tool_name") || step.text.contains("parameters") || 
                step.text.contains("message_metadata") || step.text.contains("message_type")) {
                return false
            }
            
            // Hide executing messages and summaries
            let summaryPatterns = [
                "initiated", "performed", "executed", "search was conducted",
                "based on the user's request", "providing a selection",
                "the assistant", "i've", "we've", "has been", "have been",
                "was completed", "were completed", "successfully completed",
                "carried out", "undertaken", "accomplished",
                "the following", "here's what", "to summarize",
                "in summary", "overall", "in conclusion"
            ]
            
            if step.text.contains("Executing task:") || 
               step.text.contains("Executed tool") ||
               summaryPatterns.contains(where: { lowerText.contains($0) }) {
                return false
            }
            
            // Show if explicitly marked as final AND not a summary
            return metadata.isFinal && metadata.messageType != "synthesis" && metadata.messageType != "summary"
        }
        
        // For backward compatibility: hide thoughts without metadata
        if step.type == .thought {
            return false
        }
        
        // Default: hide messages without metadata (they're likely intermediate)
        return false
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