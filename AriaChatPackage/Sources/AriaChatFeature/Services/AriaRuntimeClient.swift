import Foundation
import GRPC
import NIO

/// Main client for interacting with all Aria Runtime services
public final class AriaRuntimeClient: @unchecked Sendable {
    public static let shared = AriaRuntimeClient()
    
    private let connectionManager = GRPCConnectionManager.shared
    
    private init() {}
    
    /// Connect to the Aria Runtime
    public func connect() async throws {
        try await connectionManager.connect()
    }
    
    /// Disconnect from the Aria Runtime
    public func disconnect() async {
        await connectionManager.disconnect()
    }
    
    /// Check if connected
    public var isConnected: Bool {
        get async {
            return await connectionManager.isConnected
        }
    }
    
    /// Get the current channel
    public func getChannel() async throws -> GRPCChannel {
        return try await connectionManager.getChannel()
    }
    
    // Note: AriaRuntime service doesn't exist in the backend
    // Use SessionService, TaskService, etc. instead
    
    /// Create a SessionService client
    public func makeSessionServiceClient() async throws -> Aria_SessionServiceNIOClient {
        let channel = try await getChannel()
        return Aria_SessionServiceNIOClient(channel: channel)
    }
    
    /// Create a TaskService client
    public func makeTaskServiceClient() async throws -> Aria_TaskServiceNIOClient {
        let channel = try await getChannel()
        return Aria_TaskServiceNIOClient(channel: channel)
    }
    
    /// Create a NotificationService client
    public func makeNotificationServiceClient() async throws -> Aria_NotificationServiceNIOClient {
        let channel = try await getChannel()
        return Aria_NotificationServiceNIOClient(channel: channel)
    }
    
    /// Create a ContainerService client
    public func makeContainerServiceClient() async throws -> Aria_ContainerServiceNIOClient {
        let channel = try await getChannel()
        return Aria_ContainerServiceNIOClient(channel: channel)
    }
    
    /// Create a BundleService client
    public func makeBundleServiceClient() async throws -> Aria_BundleServiceNIOClient {
        let channel = try await getChannel()
        return Aria_BundleServiceNIOClient(channel: channel)
    }
}