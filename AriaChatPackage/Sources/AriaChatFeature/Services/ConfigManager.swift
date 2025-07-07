import Foundation
import Security

/// Configuration data models matching the MAGIC-AUTH spec
public struct AriaConfig: Codable {
    public let version: String
    public let magicNumber: String
    public let createdAt: Date
    public var deviceInfo: DeviceInfo
    public var auth: AuthConfig?
    public var api: APIConfig
    public var preferences: PreferencesConfig
    public var cache: CacheConfig
    
    public init(magicNumber: String) {
        self.version = "1.0"
        self.magicNumber = magicNumber
        self.createdAt = Date()
        self.deviceInfo = DeviceInfo()
        self.auth = nil
        self.api = APIConfig()
        self.preferences = PreferencesConfig()
        self.cache = CacheConfig()
    }
}

public struct DeviceInfo: Codable {
    public let appVersion: String
    public let osVersion: String
    public let machineId: String
    public let installId: String
    
    public init() {
        // Get app version from bundle
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        // Get macOS version
        let version = ProcessInfo.processInfo.operatingSystemVersion
        self.osVersion = "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        
        // Generate machine ID based on hardware UUID
        self.machineId = DeviceInfo.generateMachineId()
        
        // Generate unique install ID
        self.installId = "inst_\(Int(Date().timeIntervalSince1970 * 1000))"
    }
    
    private static func generateMachineId() -> String {
        // Try to get hardware UUID from IOKit
        let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard platformExpert != 0 else {
            return UUID().uuidString
        }
        
        defer { IOObjectRelease(platformExpert) }
        
        let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, "IOPlatformUUID" as CFString, kCFAllocatorDefault, 0)
        
        if let serialNumber = serialNumberAsCFString?.takeRetainedValue() as? String {
            return serialNumber
        }
        
        // Fallback to generated UUID
        return UUID().uuidString
    }
}

public struct AuthConfig: Codable {
    public var linked: Bool
    public var linkedAt: Date?
    public var userEmail: String?
    public var userId: String?
    public var accessTokenRef: String? // Keychain reference
    public var refreshTokenRef: String? // Keychain reference
    public var expiresAt: Date?
    
    public init() {
        self.linked = false
        self.linkedAt = nil
        self.userEmail = nil
        self.userId = nil
        self.accessTokenRef = nil
        self.refreshTokenRef = nil
        self.expiresAt = nil
    }
}

public struct APIConfig: Codable {
    public var baseUrl: String
    public var wsUrl: String
    public var uploadEndpoint: String
    
    public init() {
        self.baseUrl = "https://api.aria.dev"
        self.wsUrl = "wss://api.aria.dev"
        self.uploadEndpoint = "/api/v1/bundles/upload"
    }
}

public struct PreferencesConfig: Codable {
    public var notifications: NotificationPreferences
    public var autoUpdate: Bool
    public var telemetry: Bool
    public var theme: String
    
    public init() {
        self.notifications = NotificationPreferences()
        self.autoUpdate = true
        self.telemetry = true
        self.theme = "system"
    }
}

public struct NotificationPreferences: Codable {
    public var enabled: Bool
    public var sound: Bool
    public var badge: Bool
    
    public init() {
        self.enabled = true
        self.sound = true
        self.badge = true
    }
}

public struct CacheConfig: Codable {
    public var lastSync: Date?
    public var bundleCacheDir: String
    public var maxCacheSizeMb: Int
    
    public init() {
        self.lastSync = nil
        self.bundleCacheDir = "~/aria/cache/bundles"
        self.maxCacheSizeMb = 500
    }
}

/// Manages configuration file at ~/aria/config.json with secure permissions
@MainActor
public class ConfigManager: ObservableObject {
    public static let shared = ConfigManager()
    
    @Published public private(set) var config: AriaConfig?
    @Published public private(set) var isLoaded = false
    
    private let configPath: URL
    private let ariaDirectory: URL
    
    private init() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        self.ariaDirectory = homeDirectory.appendingPathComponent("aria")
        self.configPath = ariaDirectory.appendingPathComponent("config.json")
    }
    
    /// Load configuration from disk, creating default if needed
    public func loadConfig() async throws {
        print("ConfigManager: Loading configuration from \(configPath.path)")
        
        // Ensure aria directory exists
        try await ensureAriaDirectoryExists()
        
        if FileManager.default.fileExists(atPath: configPath.path) {
            // Load existing config
            let data = try Data(contentsOf: configPath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let loadedConfig = try decoder.decode(AriaConfig.self, from: data)
            self.config = loadedConfig
            print("ConfigManager: Loaded existing config with magic number: \(loadedConfig.magicNumber.prefix(8))...")
        } else {
            // Create new config with magic number
            let magicNumber = UUID().uuidString
            let newConfig = AriaConfig(magicNumber: magicNumber)
            
            try await saveConfig(newConfig)
            self.config = newConfig
            print("ConfigManager: Created new config with magic number: \(magicNumber.prefix(8))...")
        }
        
        self.isLoaded = true
    }
    
    /// Save configuration to disk with secure permissions
    public func saveConfig(_ config: AriaConfig) async throws {
        print("ConfigManager: Saving configuration")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(config)
        try data.write(to: configPath, options: .atomic)
        
        // Set secure file permissions (600 - user read/write only)
        try await setSecureFilePermissions()
        
        self.config = config
        print("ConfigManager: Configuration saved successfully")
    }
    
    /// Update auth configuration
    public func updateAuth(_ authConfig: AuthConfig) async throws {
        guard var currentConfig = self.config else {
            throw ConfigError.configNotLoaded
        }
        
        currentConfig.auth = authConfig
        try await saveConfig(currentConfig)
    }
    
    /// Get current magic number
    public func getMagicNumber() -> String? {
        return config?.magicNumber
    }
    
    /// Check if user is authenticated
    public func isAuthenticated() -> Bool {
        return config?.auth?.linked == true
    }
    
    /// Get auth login URL
    public func getAuthLoginURL() -> URL? {
        guard let magicNumber = getMagicNumber() else { return nil }
        return URL(string: "https://app.aria.dev/auth/login?magic=\(magicNumber)")
    }
    
    // MARK: - Private Methods
    
    private func ensureAriaDirectoryExists() async throws {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: ariaDirectory.path) {
            try fileManager.createDirectory(at: ariaDirectory, withIntermediateDirectories: true)
            print("ConfigManager: Created aria directory at \(ariaDirectory.path)")
        }
    }
    
    private func setSecureFilePermissions() async throws {
        let fileManager = FileManager.default
        
        // Set file permissions to 600 (user read/write only)
        try fileManager.setAttributes([
            .posixPermissions: 0o600
        ], ofItemAtPath: configPath.path)
        
        print("ConfigManager: Set secure file permissions (600) for config.json")
    }
}

/// Configuration-related errors
public enum ConfigError: Error, LocalizedError {
    case configNotLoaded
    case invalidMagicNumber
    case fileSystemError(String)
    
    public var errorDescription: String? {
        switch self {
        case .configNotLoaded:
            return "Configuration not loaded"
        case .invalidMagicNumber:
            return "Invalid magic number format"
        case .fileSystemError(let message):
            return "File system error: \(message)"
        }
    }
}