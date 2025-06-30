import Foundation

/// Centralized manager for message visibility rules across different UI contexts
enum MessageVisibilityManager {
    
    /// Context where messages are being displayed
    enum DisplayContext {
        case mainChat
        case detailPane
        case sidePanel
    }
    
    /// Determines if a step should be visible in the given context
    static func isVisible(_ step: EnhancedStep, in context: DisplayContext) -> Bool {
        switch context {
        case .mainChat:
            return isVisibleInMainChat(step)
        case .detailPane:
            return true // All steps are visible in detail pane
        case .sidePanel:
            return isVisibleInSidePanel(step)
        }
    }
    
    /// Main chat visibility rules
    private static func isVisibleInMainChat(_ step: EnhancedStep) -> Bool {
        // Delegate to existing MessageFilterUtils for backward compatibility
        return MessageFilterUtils.isVisibleInMainChat(step)
    }
    
    /// Side panel visibility rules
    private static func isVisibleInSidePanel(_ step: EnhancedStep) -> Bool {
        // Show all non-user messages in side panel
        return step.type != .userMessage
    }
    
    /// Filters a collection of steps based on display context
    static func filterSteps(_ steps: [EnhancedStep], for context: DisplayContext) -> [EnhancedStep] {
        return steps.filter { isVisible($0, in: context) }
    }
    
    /// Groups consecutive messages of the same type for better visual organization
    static func groupConsecutiveMessages(_ steps: [EnhancedStep]) -> [[EnhancedStep]] {
        guard !steps.isEmpty else { return [] }
        
        var groups: [[EnhancedStep]] = []
        var currentGroup: [EnhancedStep] = [steps[0]]
        
        for i in 1..<steps.count {
            let current = steps[i]
            let previous = steps[i-1]
            
            // Group if same type and both are tools or responses
            if current.type == previous.type && 
               (current.type == .tool || current.type == .response) {
                currentGroup.append(current)
            } else {
                groups.append(currentGroup)
                currentGroup = [current]
            }
        }
        
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }
        
        return groups
    }
    
    /// Determines appropriate spacing between two steps
    static func spacing(between current: EnhancedStep, and next: EnhancedStep) -> CGFloat {
        // Group consecutive tool calls with minimal spacing
        if current.type == .tool && next.type == .tool {
            return 4
        }
        // Group consecutive responses with small spacing
        else if current.type == .response && next.type == .response {
            return 6
        }
        // Larger spacing between different message types
        else if current.type != next.type {
            return 16
        }
        // Default spacing
        else {
            return 10
        }
    }
    
    /// Determines if a step should have a highlight background
    static func shouldHighlight(_ step: EnhancedStep, activeHighlightId: String?) -> Bool {
        return activeHighlightId == step.id
    }
    
    /// Determines if a step is clickable (shows detail pane on click)
    static func isClickable(_ step: EnhancedStep) -> Bool {
        switch step.type {
        case .tool, .thought, .response:
            return true
        case .userMessage:
            return false
        }
    }
}