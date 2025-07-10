import SwiftUI

/// Root view that conditionally renders onboarding or chat interface
/// based on authentication state
public struct AriaRootView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showOnboarding = true
    @State private var animateTransition = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Large transparent canvas for complete freedom
            Color.clear
                .frame(width: 2000, height: 1200)
            
            if showOnboarding {
                // Onboarding view
                OnboardingView()
                    .opacity(animateTransition ? 0 : 1)
                    .scaleEffect(animateTransition ? 0.95 : 1.0)
                    .animation(.timingCurve(0.25, 1, 0.5, 1, duration: 0.4), value: animateTransition)
            } else {
                // Chat interface
                GlassmorphicChatbar()
                    .opacity(animateTransition ? 1 : 0)
                    .scaleEffect(animateTransition ? 1.0 : 1.05)
                    .animation(.timingCurve(0.25, 1, 0.5, 1, duration: 0.4).delay(0.2), value: animateTransition)
            }
        }
        .onReceive(authManager.$isAuthenticated) { isAuthenticated in
            print("AriaRootView: Authentication state changed to: \(isAuthenticated)")
            updateViewState(authenticated: isAuthenticated)
        }
        .onAppear {
            // Set initial state based on current auth status
            let initialShowOnboarding = !authManager.isAuthenticated
            print("AriaRootView: onAppear - isAuthenticated: \(authManager.isAuthenticated), showOnboarding: \(initialShowOnboarding)")
            showOnboarding = initialShowOnboarding
        }
    }
    
    private func updateViewState(authenticated: Bool) {
        print("AriaRootView: updateViewState - authenticated: \(authenticated), showOnboarding: \(showOnboarding)")
        
        if authenticated && showOnboarding {
            // User just signed in - animate transition
            print("AriaRootView: Starting transition from onboarding to chat")
            animateTransition = true
            
            // After animation delay, switch views
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                print("AriaRootView: Completing transition to chat interface")
                showOnboarding = false
                animateTransition = true
            }
        } else if !authenticated && !showOnboarding {
            // User signed out - immediate switch back to onboarding
            print("AriaRootView: Switching back to onboarding")
            showOnboarding = true
            animateTransition = false
        }
    }
}

#Preview {
    AriaRootView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(BlurSettings.shared)
        .environmentObject(ThemeSettings.shared)
        .frame(width: 800, height: 600)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}