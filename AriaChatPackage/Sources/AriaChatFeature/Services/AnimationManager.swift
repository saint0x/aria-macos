import SwiftUI
import Combine

/// Production-grade animation coordination system
/// Prevents conflicts, manages performance, and coordinates complex animation sequences
@MainActor
public class AnimationManager: ObservableObject {
    public static let shared = AnimationManager()
    
    // MARK: - Animation State Management
    
    @Published private var activeAnimations: Set<String> = []
    @Published private var animationQueue: [AnimationTask] = []
    @Published public private(set) var isPerformingComplexAnimation = false
    
    private var animationTimers: [String: Timer] = [:]
    private var performanceMetrics = AnimationPerformanceMetrics()
    
    // MARK: - Animation Coordination
    
    /// Coordinates message entry animations with proper sequencing
    public func animateMessageEntry(messageId: String, index: Int, totalMessages: Int) -> Animation {
        let animationId = "message-entry-\(messageId)"
        
        // Defer state changes to avoid publishing during view updates
        Task { @MainActor in
            // Cancel any conflicting animations for the same message
            self.cancelAnimation(id: animationId)
            
            // Track animation with proper delay
            let baseDelay = min(Double(index) * 0.04, 0.8)
            let performanceAdjustedDelay = self.adjustDelayForPerformance(baseDelay)
            self.trackAnimation(id: animationId, duration: 0.3 + performanceAdjustedDelay)
        }
        
        // Calculate delay for return value without modifying state
        let baseDelay = min(Double(index) * 0.04, 0.8) // Cap at 800ms for long lists
        let performanceAdjustedDelay = adjustDelayForPerformanceReadOnly(baseDelay)
        
        return AnimationSystem.slideUpFade.delay(performanceAdjustedDelay)
    }
    
    /// Coordinates scroll animations with message animations
    public func coordinatedScrollAnimation(duration: Double = 0.5) -> Animation {
        let animationId = "coordinated-scroll"
        
        // Check animation state without triggering updates
        let hasMessageAnimations = activeAnimations.contains { $0.contains("message-entry") }
        let adjustedDuration = hasMessageAnimations ? duration * 1.2 : duration
        
        // Defer state changes to avoid publishing during view updates
        Task { @MainActor in
            self.trackAnimation(id: animationId, duration: adjustedDuration)
        }
        
        return Animation.easeOut(duration: adjustedDuration)
    }
    
    /// Manages complex multi-step animations
    public func executeComplexAnimation<T>(
        id: String,
        steps: [AnimationStep],
        onCompletion: @escaping (T?) -> Void = { _ in }
    ) {
        guard !isPerformingComplexAnimation else {
            // Queue for later execution
            animationQueue.append(AnimationTask(id: id, steps: steps))
            return
        }
        
        isPerformingComplexAnimation = true
        executeAnimationSteps(id: id, steps: steps) { [weak self] result in
            self?.isPerformingComplexAnimation = false
            self?.processNextQueuedAnimation()
            onCompletion(result)
        }
    }
    
    // MARK: - Performance Management
    
    /// Adjusts animation parameters based on current performance
    private func adjustDelayForPerformance(_ baseDelay: Double) -> Double {
        let activeCount = activeAnimations.count
        
        switch activeCount {
        case 0...5: return baseDelay
        case 6...15: return baseDelay * 1.2 // Slight slowdown
        case 16...30: return baseDelay * 1.5 // More conservative
        default: return min(baseDelay * 2.0, 1.0) // Cap at 1 second
        }
    }
    
    /// Read-only version that doesn't trigger state changes during view updates
    private func adjustDelayForPerformanceReadOnly(_ baseDelay: Double) -> Double {
        let activeCount = activeAnimations.count
        
        switch activeCount {
        case 0...5: return baseDelay
        case 6...15: return baseDelay * 1.2 // Slight slowdown
        case 16...30: return baseDelay * 1.5 // More conservative
        default: return min(baseDelay * 2.0, 1.0) // Cap at 1 second
        }
    }
    
    /// Monitors animation performance and adjusts accordingly
    private func trackAnimation(id: String, duration: Double) {
        activeAnimations.insert(id)
        performanceMetrics.recordAnimationStart()
        
        // Auto-cleanup animation tracking with proper actor isolation
        let timer = Timer.scheduledTimer(withTimeInterval: duration + 0.1, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.activeAnimations.remove(id)
                self.animationTimers.removeValue(forKey: id)
                self.performanceMetrics.recordAnimationEnd()
            }
        }
        
        animationTimers[id] = timer
    }
    
    /// Cancels specific animation and cleans up resources
    public func cancelAnimation(id: String) {
        activeAnimations.remove(id)
        animationTimers[id]?.invalidate()
        animationTimers.removeValue(forKey: id)
    }
    
    /// Emergency cleanup for performance recovery
    public func clearAllAnimations() {
        activeAnimations.removeAll()
        animationTimers.values.forEach { $0.invalidate() }
        animationTimers.removeAll()
        isPerformingComplexAnimation = false
        animationQueue.removeAll()
        
        print("🔥 AnimationManager: Emergency cleanup performed")
    }
    
    // MARK: - Animation Queue Processing
    
    private func executeAnimationSteps<T>(
        id: String, 
        steps: [AnimationStep], 
        onCompletion: @escaping (T?) -> Void
    ) {
        guard !steps.isEmpty else {
            onCompletion(nil)
            return
        }
        
        var remainingSteps = steps
        let currentStep = remainingSteps.removeFirst()
        
        trackAnimation(id: "\(id)-step-\(currentStep.name)", duration: currentStep.duration)
        
        withAnimation(currentStep.animation) {
            currentStep.action()
        }
        
        // Schedule next step with proper MainActor isolation
        Task {
            try? await Task.sleep(nanoseconds: UInt64(currentStep.duration * 1_000_000_000))
            await MainActor.run {
                if remainingSteps.isEmpty {
                    onCompletion(nil)
                } else {
                    self.executeAnimationSteps(id: id, steps: remainingSteps, onCompletion: onCompletion)
                }
            }
        }
    }
    
    private func processNextQueuedAnimation() {
        guard !animationQueue.isEmpty else { return }
        
        let nextTask = animationQueue.removeFirst()
        executeComplexAnimation(id: nextTask.id, steps: nextTask.steps, onCompletion: { (_: Void?) in })
    }
    
    // MARK: - Smart Animation Policies
    
    /// Determines if animation should be reduced for performance
    public var shouldReduceAnimations: Bool {
        activeAnimations.count > 20 || performanceMetrics.averageFrameTime > 16.67 // 60fps threshold
    }
    
    /// Gets performance-optimized animation for current conditions
    public func optimizedAnimation(base: Animation) -> Animation {
        guard shouldReduceAnimations else { return base }
        
        // Reduce animation complexity under load
        return Animation.easeOut(duration: 0.2)
    }
    
    private init() {
        startPerformanceMonitoring()
    }
    
    private func startPerformanceMonitoring() {
        // Monitor performance every 5 seconds with proper actor isolation
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.performanceMetrics.updateMetrics()
                
                // Auto-cleanup if too many animations are running
                if self.activeAnimations.count > 50 {
                    self.clearAllAnimations()
                }
            }
        }
    }
}

// MARK: - Supporting Types

public struct AnimationStep {
    let name: String
    let animation: Animation
    let duration: Double
    let action: () -> Void
    
    public init(name: String, animation: Animation, duration: Double, action: @escaping () -> Void) {
        self.name = name
        self.animation = animation
        self.duration = duration
        self.action = action
    }
}

private struct AnimationTask {
    let id: String
    let steps: [AnimationStep]
}

private class AnimationPerformanceMetrics {
    private var frameStartTime = CACurrentMediaTime()
    private var frameTimes: [Double] = []
    private let maxFrameSamples = 60
    
    var averageFrameTime: Double {
        guard !frameTimes.isEmpty else { return 0 }
        return frameTimes.reduce(0, +) / Double(frameTimes.count)
    }
    
    func recordAnimationStart() {
        frameStartTime = CACurrentMediaTime()
    }
    
    func recordAnimationEnd() {
        let frameTime = (CACurrentMediaTime() - frameStartTime) * 1000 // Convert to ms
        
        frameTimes.append(frameTime)
        if frameTimes.count > maxFrameSamples {
            frameTimes.removeFirst()
        }
    }
    
    func updateMetrics() {
        // Could add memory pressure monitoring, battery level checks, etc.
        if averageFrameTime > 20 { // 50fps threshold
            print("⚠️ AnimationManager: Performance degradation detected (avg: \(String(format: "%.2f", averageFrameTime))ms)")
        }
    }
}

// MARK: - View Extensions for Enhanced Animation System

extension View {
    /// Production-ready message entry animation
    public func animateMessageEntry(messageId: String, index: Int, totalMessages: Int) -> some View {
        let animation = AnimationManager.shared.animateMessageEntry(
            messageId: messageId, 
            index: index, 
            totalMessages: totalMessages
        )
        
        return self
            .slideUpFade(isVisible: true)
            .animation(animation, value: totalMessages)
    }
    
    /// Performance-optimized animation wrapper
    public func optimizedAnimation(_ baseAnimation: Animation, value: some Equatable) -> some View {
        let optimizedAnim = AnimationManager.shared.optimizedAnimation(base: baseAnimation)
        return self.animation(optimizedAnim, value: value)
    }
}