import Foundation

/// Deterministic rules for message visibility in the main chat
/// Priority order (highest to lowest):
/// 1. User messages → Always visible
/// 2. Tool calls (indented) → Always visible
/// 3. Final responses → Always visible
/// 4. Everything else → Hidden
enum MessageVisibilityRules {
    
    /// Single source of truth for main chat visibility
    static func isVisibleInMainChat(_ step: EnhancedStep) -> Bool {
        let decision = makeVisibilityDecision(step)
        return decision.isVisible
    }
    
    private struct VisibilityDecision {
        let isVisible: Bool
        let reason: String
    }
    
    private static func makeVisibilityDecision(_ step: EnhancedStep) -> VisibilityDecision {
        // Rule 1: User messages are ALWAYS visible
        if step.type == .userMessage {
            return VisibilityDecision(isVisible: true, reason: "User message")
        }
        
        // Rule 2: Tool calls (indented) are ALWAYS visible
        if step.type == .tool && step.isIndented {
            return VisibilityDecision(isVisible: true, reason: "Indented tool call")
        }
        
        // Rule 3: Only show responses from finalResponse event
        if step.type == .response {
            // Only show if this came from the finalResponse event (ID starts with "response-")
            if step.id.hasPrefix("response-") {
                return VisibilityDecision(isVisible: true, reason: "Final response event")
            }
            
            // Hide all other responses (from message events with "msg-" prefix)
            // This includes assistant messages that should have been skipped in processing
            if step.id.hasPrefix("msg-") {
                return VisibilityDecision(isVisible: false, reason: "Assistant message event (should be skipped)")
            }
            
            return VisibilityDecision(isVisible: false, reason: "Message event response (not final)")
        }
        
        // Rule 4: Everything else is hidden
        return VisibilityDecision(isVisible: false, reason: "Default hide")
    }
    
    /// Check if text looks like JSON
    private static func looksLikeJSON(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for JSON object or array
        if (trimmed.hasPrefix("{") && trimmed.hasSuffix("}")) ||
           (trimmed.hasPrefix("[") && trimmed.hasSuffix("]")) {
            return true
        }
        
        // Check for JSON-like content
        if text.contains("\"") && text.contains(":") && text.contains("{") {
            return true
        }
        
        // Check for specific JSON fields that shouldn't be shown
        let jsonIndicators = ["tool_name", "parameters", "message_metadata", "message_type", "tool_result"]
        return jsonIndicators.contains { text.contains($0) }
    }
    
    /// Check if text contains summary patterns
    private static func containsSummaryPattern(_ lowerText: String) -> Bool {
        let summaryPatterns = [
            // Action summaries
            "initiated", "performed", "executed", "completed",
            "was conducted", "has been", "have been",
            "was completed", "were completed", "successfully completed",
            "carried out", "undertaken", "accomplished",
            
            // Meta descriptions
            "the assistant", "i've", "we've",
            "based on the user's request", "providing a selection",
            
            // Summary indicators
            "the following", "here's what", "to summarize",
            "in summary", "overall", "in conclusion",
            
            // Task descriptions
            "executing task:", "executed tool"
        ]
        
        return summaryPatterns.contains { lowerText.contains($0) }
    }
}