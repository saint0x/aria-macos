import SwiftUI

/// Onboarding view that shows when user is not authenticated
/// Matches the React OnboardingCard design
public struct OnboardingView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background blur effect
            Color.clear
                .ignoresSafeArea()
            
            // Onboarding card with expand-in animation
            VStack {
                Spacer()
                
                onboardingCard
                    .scaleEffect(isLoading ? 0.98 : 1.0)
                    .opacity(isLoading ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isLoading)
                    // expand-in animation equivalent: 0.3s cubic-bezier(0.25, 1, 0.5, 1)
                    .scaleEffect(1.0)
                    .opacity(1.0)
                    .animation(.timingCurve(0.25, 1, 0.5, 1, duration: 0.3), value: authManager.isAuthenticated)
                
                Spacer()
            }
        }
        .onReceive(authManager.$authError) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var onboardingCard: some View {
        VStack(spacing: 0) {
            // Card content
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text("Welcome to Aria")
                        .font(.system(size: 30, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .fontDesign(.default)
                    
                    Text("Log in with Google and you will be redirected back to the macOS app.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 320)
                }
                
                // Sign in button
                signInButton
            }
            .padding(32)
        }
        .frame(maxWidth: 400)
        .background(
            // Glassmorphic background matching ARIA-UI specs
            RoundedRectangle(cornerRadius: 22, style: .continuous) // 2xl radius (22px)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(red: 38/255, green: 38/255, blue: 38/255, opacity: 0.3)) // neutral-800/30
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 12.5, // apple-xl shadow equivalent
            x: 0,
            y: 10
        )
        .shadow(
            color: .black.opacity(0.04),
            radius: 5,
            x: 0,
            y: 4
        )
        .padding(.horizontal, 16)
    }
    
    private var signInButton: some View {
        Button(action: handleSignIn) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                }
                
                Text(isLoading ? "Signing in..." : "Sign in with Google")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous) // lg radius (12px)
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: 1,
                        x: 0,
                        y: 1
                    )
                    .shadow(
                        color: .white.opacity(0.1),
                        radius: 1,
                        x: 0,
                        y: -1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
        }
        .disabled(isLoading)
        .buttonStyle(OnboardingButtonStyle())
    }
    
    private func handleSignIn() {
        isLoading = true
        
        Task {
            do {
                await authManager.startAuthFlow()
                // Keep loading state until auth callback or timeout
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second minimum
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to open browser: \(error.localizedDescription)"
                    showError = true
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

/// Custom button style for the onboarding sign-in button
private struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Preview for development
#Preview {
    OnboardingView()
        .frame(width: 800, height: 600)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}