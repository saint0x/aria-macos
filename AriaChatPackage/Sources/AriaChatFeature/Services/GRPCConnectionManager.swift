import Foundation
import GRPC
import NIO
import NIOSSL
import Logging

/// Manages the gRPC connection to the Aria Runtime
public actor GRPCConnectionManager {
    public static let shared = GRPCConnectionManager()
    
    private var channel: GRPCChannel?
    private let eventLoopGroup: EventLoopGroup
    private let host: String
    private let port: Int
    private let useTLS: Bool
    private let logger = Logger(label: "GRPCConnectionManager")
    
    private init() {
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        // Check environment variables for configuration
        self.host = ProcessInfo.processInfo.environment["ARIA_RUNTIME_HOST"] ?? "localhost"
        self.port = Int(ProcessInfo.processInfo.environment["ARIA_RUNTIME_PORT"] ?? "50052") ?? 50052
        self.useTLS = ProcessInfo.processInfo.environment["ARIA_RUNTIME_TLS"] == "true"
        
        logger.info("gRPC configuration: \(useTLS ? "https" : "http")://\(host):\(port)")
        
        // Connect on initialization
        Task {
            do {
                try await connect()
            } catch {
                logger.error("Failed to connect on startup: \(error)")
            }
        }
    }
    
    deinit {
        // Note: We cannot call async methods in deinit
        // The connection will be cleaned up when the event loop group shuts down
        try? eventLoopGroup.syncShutdownGracefully()
    }
    
    /// Connect to the Aria Runtime
    public func connect() async throws {
        guard channel == nil else {
            logger.info("Already connected to gRPC server")
            return
        }
        
        logger.info("Connecting to gRPC server at \(host):\(port)")
        print("GRPCConnectionManager: Connecting to \(host):\(port)")
        
        // Create a single persistent channel (not a pool)
        let channel = ClientConnection.insecure(group: eventLoopGroup)
            .connect(host: host, port: port)
        
        self.channel = channel
        
        logger.info("Successfully connected to gRPC server")
        print("GRPCConnectionManager: Channel created successfully")
    }
    
    /// Disconnect from the Aria Runtime
    public func disconnect() {
        guard let channel = channel else { return }
        
        logger.info("Disconnecting from gRPC server")
        _ = channel.close()
        self.channel = nil
    }
    
    /// Get the current channel, connecting if necessary
    public func getChannel() async throws -> GRPCChannel {
        if channel == nil {
            try await connect()
        }
        
        guard let channel = channel else {
            throw GRPCError.notConnected
        }
        
        return channel
    }
    
    /// Check if currently connected
    public var isConnected: Bool {
        return channel != nil
    }
}

// MARK: - Errors

public enum GRPCError: LocalizedError {
    case notConnected
    case connectionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to gRPC server"
        case .connectionFailed(let reason):
            return "Failed to connect to gRPC server: \(reason)"
        }
    }
}