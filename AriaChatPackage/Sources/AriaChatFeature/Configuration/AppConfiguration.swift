import SwiftUI
import Foundation

/// Production-grade configuration system
/// Centralizes all hardcoded values and provides environment-specific settings
public struct AppConfiguration: Sendable {
    public static let shared = AppConfiguration()
    
    // MARK: - UI Configuration
    
    public struct UI {
        // Chat Interface
        public static let maxChatWidth: CGFloat = 512
        public static let expandedChatHeight: CGFloat = 450
        public static let chatPadding: CGFloat = 14
        public static let messagePadding: CGFloat = 12
        public static let chatCornerRadius: CGFloat = 22
        
        // Animation Timings
        public static let defaultAnimationDuration: Double = 0.3
        public static let quickAnimationDuration: Double = 0.2
        public static let slowAnimationDuration: Double = 0.5
        public static let staggerDelay: Double = 0.04
        public static let maxStaggerDelay: Double = 0.8
        
        // Notification Timings
        public static let notificationDisplayDuration: Double = 2.5
        public static let notificationFadeOutDuration: Double = 0.2
        
        // Scroll Configuration
        public static let scrollDebounceInterval: TimeInterval = 0.1
        public static let autoScrollDelay: TimeInterval = 0.5
        public static let scrollAnimationDuration: Double = 0.5
        
        // Visual Effects
        public static let defaultBlurIntensity: CGFloat = 24
        public static let shadowRadius: CGFloat = 8
        public static let borderOpacity: Double = 0.3
    }
    
    // MARK: - Performance Configuration
    
    public struct Performance {
        // Memory Management
        public static let maxMessagesInMemory: Int = 100
        public static let messageCleanupThreshold: Int = 120
        public static let memoryCheckInterval: TimeInterval = 30
        public static let forceCleanupThreshold: Int = 500
        
        // Animation Performance
        public static let maxConcurrentAnimations: Int = 20
        public static let performanceMonitorInterval: TimeInterval = 5.0
        public static let targetFrameTime: Double = 16.67 // 60fps in milliseconds
        public static let performanceThresholdFrameTime: Double = 20.0 // 50fps
        
        // Network & Processing
        public static let requestTimeoutInterval: TimeInterval = 60
        public static let resourceTimeoutInterval: TimeInterval = 3600
        public static let maxRetryAttempts: Int = 3
        public static let retryBaseDelay: TimeInterval = 1.0
    }
    
    // MARK: - Development Configuration
    
    public struct Development {
        public static let enablePerformanceLogging: Bool = true
        public static let enableAnimationDebugging: Bool = false
        public static let enableStateValidation: Bool = true
        public static let logLevel: LogLevel = .info
        public static let enableMemoryWarnings: Bool = true
    }
    
    // MARK: - Environment-Specific Configuration
    
    public enum Environment {
        case development
        case staging  
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }
    
    public struct EnvironmentConfig {
        let apiTimeout: TimeInterval
        let enableLogging: Bool
        let animationScale: Double
        let performanceOptimizations: Bool
        
        static func config(for environment: Environment) -> EnvironmentConfig {
            switch environment {
            case .development:
                return EnvironmentConfig(
                    apiTimeout: 30,
                    enableLogging: true,
                    animationScale: 1.0,
                    performanceOptimizations: false
                )
            case .staging:
                return EnvironmentConfig(
                    apiTimeout: 45,
                    enableLogging: true,
                    animationScale: 1.0,
                    performanceOptimizations: true
                )
            case .production:
                return EnvironmentConfig(
                    apiTimeout: 60,
                    enableLogging: false,
                    animationScale: 0.8, // Slightly faster for production
                    performanceOptimizations: true
                )
            }
        }
    }
    
    // MARK: - Dynamic Configuration
    
    // Dynamic configuration moved to separate class for thread safety
    public static func getUserAnimationSpeed() -> Double {
        UserDefaults.standard.double(forKey: "userPreferredAnimationSpeed") != 0 
            ? UserDefaults.standard.double(forKey: "userPreferredAnimationSpeed") 
            : 1.0
    }
    
    public static func getUserReducedMotion() -> Bool {
        UserDefaults.standard.bool(forKey: "userReducedMotion")
    }
    
    public static func getUserMaxMessages() -> Int {
        let stored = UserDefaults.standard.integer(forKey: "userMaxMessages")
        return stored != 0 ? stored : Performance.maxMessagesInMemory
    }
    
    // MARK: - Computed Properties
    
    public static var currentEnvironmentConfig: EnvironmentConfig {
        EnvironmentConfig.config(for: Environment.current)
    }
    
    public static var effectiveAnimationDuration: Double {
        let base = UI.defaultAnimationDuration
        let environmentScale = currentEnvironmentConfig.animationScale
        let userScale = getUserReducedMotion() ? 0.5 : getUserAnimationSpeed()
        return base * environmentScale * userScale
    }
    
    public static var effectiveMaxMessages: Int {
        let base = Performance.maxMessagesInMemory
        let userPreference = getUserMaxMessages()
        return min(max(userPreference, 50), 200) // Clamp between 50-200
    }
    
    // MARK: - Configuration Validation
    
    public static func validateConfiguration() -> [String] {
        var issues: [String] = []
        
        if UI.maxChatWidth < 300 {
            issues.append("Chat width too small")
        }
        
        if Performance.maxMessagesInMemory < 10 {
            issues.append("Max messages too low")
        }
        
        if UI.defaultAnimationDuration <= 0 {
            issues.append("Invalid animation duration")
        }
        
        return issues
    }
    
    private init() {
        // Validate configuration on startup
        let issues = Self.validateConfiguration()
        if !issues.isEmpty {
            print("⚠️ Configuration issues detected: \(issues)")
        }
    }
}

// MARK: - Supporting Types

public enum LogLevel: Int, CaseIterable, Sendable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case critical = 5
    
    public var description: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
}

// MARK: - Configuration Extensions for Views

extension View {
    /// Apply configuration-driven styling
    public func configuredChatStyle() -> some View {
        self
            .frame(maxWidth: AppConfiguration.UI.maxChatWidth)
            .glassmorphic(cornerRadius: AppConfiguration.UI.chatCornerRadius)
            .padding(AppConfiguration.UI.chatPadding)
    }
    
    /// Apply performance-optimized animations
    public func configuredAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        let effectiveAnimation = animation.speed(AppConfiguration.getUserReducedMotion() ? 2.0 : 1.0)
        return self.animation(effectiveAnimation, value: value)
    }
}