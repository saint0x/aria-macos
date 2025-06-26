import SwiftUI

// Port of TypeScript animation system with exact timing curves from tailwind.config.ts
struct AnimationSystem {
    // Matches gentleTransition from animations.ts and SWIFT2.md
    static let gentleTransition = Animation
        .timingCurve(0.32, 0.72, 0, 1, duration: 0.3)
    
    // Matches defaultTransition spring animation
    static let defaultTransition = Animation
        .spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)
    
    // For dropdown menu items
    static func staggeredItemAnimation(index: Int) -> Animation {
        Animation
            .timingCurve(0.32, 0.72, 0, 1, duration: 0.2)
            .delay(Double(index) * 0.02)
    }
    
    // For expand/collapse animations - cubic-bezier(0.25, 1, 0.5, 1)
    static let expandAnimation = Animation
        .timingCurve(0.25, 1, 0.5, 1, duration: 0.3)
    
    // expand-in: 0.3s cubic-bezier(0.25, 1, 0.5, 1)
    static let expandIn = Animation
        .timingCurve(0.25, 1, 0.5, 1, duration: 0.3)
    
    // slide-up-fade: 0.3s cubic-bezier(0.25, 1, 0.5, 1)
    static let slideUpFade = Animation
        .timingCurve(0.25, 1, 0.5, 1, duration: 0.3)
    
    // slide-in-from-right: 0.35s cubic-bezier(0.25, 1, 0.5, 1)
    static let slideInFromRight = Animation
        .timingCurve(0.25, 1, 0.5, 1, duration: 0.35)
    
    // slide-out-to-right: 0.35s cubic-bezier(0.25, 1, 0.5, 1)
    static let slideOutToRight = Animation
        .timingCurve(0.25, 1, 0.5, 1, duration: 0.35)
    
    // subtle-pulse: 1.5s ease-in-out infinite
    static let subtlePulse = Animation
        .easeInOut(duration: 1.5)
        .repeatForever(autoreverses: true)
}

// Animation state modifiers matching tailwind keyframes exactly
struct SlideUpFadeModifier: ViewModifier {
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 8) // translateY(8px) from keyframes
            .animation(AnimationSystem.slideUpFade, value: isVisible)
    }
}

struct ExpandInModifier: ViewModifier {
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.97) // scale(0.97) from keyframes
            .animation(AnimationSystem.expandIn, value: isVisible)
    }
}

struct SlideInFromRightModifier: ViewModifier {
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(x: isVisible ? 0 : 400) // translateX equivalent for macOS
            .animation(AnimationSystem.slideInFromRight, value: isVisible)
    }
}

struct SlideOutToRightModifier: ViewModifier {
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(x: isVisible ? 0 : 400) // translateX equivalent for macOS
            .animation(AnimationSystem.slideOutToRight, value: isVisible)
    }
}

struct SubtlePulseModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 1.0 : 0.8)
            .onAppear {
                withAnimation(AnimationSystem.subtlePulse) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func slideUpFade(isVisible: Bool) -> some View {
        self.modifier(SlideUpFadeModifier(isVisible: isVisible))
    }
    
    func expandIn(isVisible: Bool) -> some View {
        self.modifier(ExpandInModifier(isVisible: isVisible))
    }
    
    func slideInFromRight(isVisible: Bool) -> some View {
        self.modifier(SlideInFromRightModifier(isVisible: isVisible))
    }
    
    func slideOutToRight(isVisible: Bool) -> some View {
        self.modifier(SlideOutToRightModifier(isVisible: isVisible))
    }
    
    func subtlePulse() -> some View {
        self.modifier(SubtlePulseModifier())
    }
}