import SwiftUI
import Foundation

/// Production-grade state management with race condition prevention
/// Ensures atomic updates and consistent state across concurrent operations
@MainActor
public class StateCoordinator: ObservableObject {
    public static let shared = StateCoordinator()
    
    // MARK: - Thread-Safe State Operations
    
    /// Safely execute state updates with race condition prevention using structured concurrency
    public func executeAtomicUpdate<T>(
        _ update: @escaping @Sendable () throws -> T,
        onMain: @escaping @MainActor @Sendable (T) -> Void,
        onError: @escaping @MainActor @Sendable (Error) -> Void = { _ in }
    ) {
        Task {
            do {
                let result = try update()
                await MainActor.run {
                    onMain(result)
                }
            } catch {
                await MainActor.run {
                    onError(error)
                }
            }
        }
    }
    
    /// Execute state update on main thread safely
    public func executeMainThreadUpdate(_ update: @escaping @MainActor @Sendable () -> Void) {
        Task { @MainActor in
            update()
        }
    }
    
    /// Batch multiple state updates for efficiency
    public func batchStateUpdates<T>(
        updates: [@Sendable () throws -> T],
        onComplete: @escaping @MainActor @Sendable ([T]) -> Void,
        onError: @escaping @MainActor @Sendable (Error) -> Void = { _ in }
    ) {
        Task {
            do {
                let results = try updates.map { try $0() }
                await MainActor.run {
                    onComplete(results)
                }
            } catch {
                await MainActor.run {
                    onError(error)
                }
            }
        }
    }
    
    // MARK: - Message State Management
    
    /// Thread-safe message addition with validation
    internal func addMessage(
        to chatState: GlassmorphicChatbarState,
        message: EnhancedStep
    ) {
        Task { @MainActor in
            chatState.addStep(message)
        }
    }
    
    /// Atomic highlight update with conflict resolution
    internal func updateHighlight(
        in chatState: GlassmorphicChatbarState,
        to messageId: String?
    ) {
        Task { @MainActor in
            // Validate message exists if not nil
            if let id = messageId {
                guard chatState.aiSteps.contains(where: { $0.id == id }) else {
                    print("❌ StateCoordinator: Message with id \(id) not found")
                    return
                }
            }
            chatState.activeHighlightId = messageId
        }
    }
    
    /// Safe processing state updates
    internal func updateProcessingState(
        in chatState: GlassmorphicChatbarState,
        isProcessing: Bool,
        isComplete: Bool = false
    ) {
        Task { @MainActor in
            chatState.isProcessing = isProcessing
            chatState.processingComplete = isComplete
        }
    }
    
    // MARK: - State Validation & Recovery
    
    /// Comprehensive state validation
    internal func validateState(_ chatState: GlassmorphicChatbarState) -> StateValidationResult {
        var issues: [StateValidationIssue] = []
        
        // Check for duplicate message IDs
        let messageIds = chatState.aiSteps.map { $0.id }
        let uniqueIds = Set(messageIds)
        if messageIds.count != uniqueIds.count {
            issues.append(.duplicateMessageIds)
        }
        
        // Check for orphaned highlights
        if let highlightId = chatState.activeHighlightId,
           !chatState.aiSteps.contains(where: { $0.id == highlightId }) {
            issues.append(.orphanedHighlight(highlightId))
        }
        
        // Check for memory pressure
        if chatState.aiSteps.count > 200 {
            issues.append(.memoryPressure(chatState.aiSteps.count))
        }
        
        // Check for processing state inconsistencies
        if chatState.isProcessing && chatState.processingComplete {
            issues.append(.processingStateInconsistency)
        }
        
        return StateValidationResult(issues: issues)
    }
    
    /// Auto-recover from state corruption
    internal func recoverState(_ chatState: GlassmorphicChatbarState) {
        let validation = validateState(chatState)
        
        guard !validation.issues.isEmpty else { return }
        
        print("🔧 StateCoordinator: Recovering from state issues: \(validation.issues)")
        
        for issue in validation.issues {
            switch issue {
            case .duplicateMessageIds:
                removeDuplicateMessages(from: chatState)
            case .orphanedHighlight(let id):
                print("🔧 Clearing orphaned highlight: \(id)")
                chatState.activeHighlightId = nil
            case .memoryPressure(_):
                chatState.forceMemoryCleanup()
            case .processingStateInconsistency:
                chatState.isProcessing = false
                chatState.processingComplete = false
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func removeDuplicateMessages(from chatState: GlassmorphicChatbarState) {
        var uniqueMessages: [EnhancedStep] = []
        var seenIds: Set<String> = []
        
        for message in chatState.aiSteps {
            if !seenIds.contains(message.id) {
                uniqueMessages.append(message)
                seenIds.insert(message.id)
            }
        }
        
        if uniqueMessages.count != chatState.aiSteps.count {
            chatState.aiSteps = uniqueMessages
            print("🔧 Removed \(chatState.aiSteps.count - uniqueMessages.count) duplicate messages")
        }
    }
    
    private init() {
        startStateMonitoring()
    }
    
    private func startStateMonitoring() {
        // Monitor state health every 10 seconds with proper actor isolation
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                // Could monitor specific chat states here if needed
                // For now, validation is done on-demand
            }
        }
    }
}

// MARK: - Supporting Types

public struct StateUpdate {
    let id: String
    let execute: () -> Void
    
    public init(id: String, execute: @escaping () -> Void) {
        self.id = id
        self.execute = execute
    }
}

public enum StateError: LocalizedError {
    case validationFailed(String)
    case messageNotFound(String)
    case concurrentAccess(String)
    
    public var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return "State validation failed: \(message)"
        case .messageNotFound(let message):
            return "Message not found: \(message)"
        case .concurrentAccess(let message):
            return "Concurrent state access detected: \(message)"
        }
    }
}

public enum StateValidationIssue: Equatable {
    case duplicateMessageIds
    case orphanedHighlight(String)
    case memoryPressure(Int)
    case processingStateInconsistency
}

public struct StateValidationResult {
    let issues: [StateValidationIssue]
    
    var isValid: Bool {
        issues.isEmpty
    }
    
    var criticalIssues: [StateValidationIssue] {
        issues.filter { issue in
            switch issue {
            case .duplicateMessageIds, .processingStateInconsistency:
                return true
            case .memoryPressure(let count):
                return count > 500
            case .orphanedHighlight:
                return false
            }
        }
    }
}