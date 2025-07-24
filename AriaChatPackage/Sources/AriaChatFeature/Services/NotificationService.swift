import Foundation
import SwiftUI

/// Service for handling real-time notifications from the SDK/firmware
/// Connects to the /api/v1/notifications/stream SSE endpoint
@MainActor
public class NotificationService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var activeNotifications: [ToastNotification] = []
    @Published public var isConnected = false
    
    // MARK: - Private Properties
    
    private let streamingClient: StreamingClient
    private var currentStreamHandle: StreamHandle?
    private let maxVisibleNotifications = 3
    
    // MARK: - Singleton
    
    public static let shared = NotificationService()
    
    private init() {
        self.streamingClient = StreamingClient()
    }
    
    // MARK: - Public Methods
    
    /// Connect to the notification stream
    public func connect() async {
        guard currentStreamHandle == nil else { return }
        
        guard let config = ConfigManager.shared.config else {
            print("❌ NotificationService: No configuration available")
            return
        }
        
        let baseURL = config.api.baseUrl
        guard let url = URL(string: "\(baseURL)\(APIEndpoints.notificationsStream)") else {
            print("❌ NotificationService: Invalid notification stream URL")
            return
        }
        
        print("🔗 NotificationService: Connecting to \(url)")
        
        currentStreamHandle = await streamingClient.streamWithDelegate(
            url: url,
            onEvent: handleNotificationEvent,
            onError: { [weak self] error in
                Task { @MainActor in
                    self?.handleStreamError(error)
                }
            }
        )
        
        isConnected = true
    }
    
    /// Disconnect from the notification stream
    public func disconnect() async {
        await currentStreamHandle?.cancel()
        currentStreamHandle = nil
        isConnected = false
        
        print("🔌 NotificationService: Disconnected")
    }
    
    /// Manually add a notification (for testing or direct display)
    public func showNotification(_ notification: ToastNotification) {
        // Remove oldest if at capacity
        if activeNotifications.count >= maxVisibleNotifications {
            activeNotifications.removeFirst()
        }
        
        activeNotifications.append(notification)
        
        // Auto-remove after duration
        Task {
            try? await Task.sleep(for: .seconds(notification.duration))
            removeNotification(withId: notification.id)
        }
    }
    
    /// Remove a specific notification
    public func removeNotification(withId id: UUID) {
        activeNotifications.removeAll { $0.id == id }
    }
    
    // MARK: - Private Methods
    
    private func handleNotificationEvent(_ event: SSEEvent) async {
        print("📬 NotificationService: Received event - type: \(event.type)")
        
        switch event.type {
        case "bundle_upload":
            await handleBundleUploadEvent(event)
        case "task_status":
            await handleTaskStatusEvent(event)
        case "tool_registration":
            await handleToolRegistrationEvent(event)
        default:
            print("⚠️ NotificationService: Unknown event type: \(event.type)")
        }
    }
    
    private func handleBundleUploadEvent(_ event: SSEEvent) async {
        do {
            let data = try event.decode(BundleUploadEvent.self)
            
            // Show notification for completion or significant progress milestones
            if data.success {
                let notification = ToastNotification(
                    title: "Bundle Uploaded",
                    message: "✓ \(data.bundleName) uploaded successfully",
                    type: .success,
                    duration: AppConfiguration.UI.notificationDisplayDuration
                )
                showNotification(notification)
            } else if let errorMessage = data.errorMessage {
                let notification = ToastNotification(
                    title: "Upload Failed",
                    message: "✗ \(data.bundleName): \(errorMessage)",
                    type: .error,
                    duration: AppConfiguration.UI.notificationDisplayDuration
                )
                showNotification(notification)
            }
            // For progress updates, we could show progress but avoid spam
        } catch {
            print("❌ NotificationService: Failed to decode bundle_upload event: \(error)")
        }
    }
    
    private func handleTaskStatusEvent(_ event: SSEEvent) async {
        do {
            let data = try event.decode(TaskStatusEvent.self)
            
            // Show notifications for final states
            switch data.newStatus {
            case "Succeeded":
                let notification = ToastNotification(
                    title: "Task Completed",
                    message: "✓ Task finished successfully",
                    type: .success,
                    duration: AppConfiguration.UI.notificationDisplayDuration
                )
                showNotification(notification)
            case "Failed":
                let notification = ToastNotification(
                    title: "Task Failed",
                    message: "✗ \(data.statusMessage)",
                    type: .error,
                    duration: AppConfiguration.UI.notificationDisplayDuration
                )
                showNotification(notification)
            default:
                // Don't show notifications for intermediate states like "Pending", "Running"
                break
            }
        } catch {
            print("❌ NotificationService: Failed to decode task_status event: \(error)")
        }
    }
    
    private func handleToolRegistrationEvent(_ event: SSEEvent) async {
        do {
            let data = try event.decode(ToolRegistrationEvent.self)
            
            if data.success {
                let progressText = if let total = data.totalTools, let count = data.registeredCount {
                    " (\(count)/\(total))"
                } else {
                    ""
                }
                
                let notification = ToastNotification(
                    title: "Tool Registered",
                    message: "✓ \(data.toolName)\(progressText)",
                    type: .success,
                    duration: AppConfiguration.UI.notificationDisplayDuration
                )
                showNotification(notification)
            } else if let errorMessage = data.errorMessage {
                let notification = ToastNotification(
                    title: "Registration Failed",
                    message: "✗ \(data.toolName): \(errorMessage)",
                    type: .error,
                    duration: AppConfiguration.UI.notificationDisplayDuration
                )
                showNotification(notification)
            }
        } catch {
            print("❌ NotificationService: Failed to decode tool_registration event: \(error)")
        }
    }
    
    private func handleStreamError(_ error: Error) {
        print("❌ NotificationService: Stream error: \(error)")
        isConnected = false
        
        // Show error notification to user
        let notification = ToastNotification(
            title: "Connection Lost",
            message: "Notification stream disconnected",
            type: .warning,
            duration: AppConfiguration.UI.notificationDisplayDuration
        )
        showNotification(notification)
        
        // Attempt to reconnect after delay
        Task {
            try? await Task.sleep(for: .seconds(5))
            await connect()
        }
    }
}

// MARK: - Supporting Data Models

/// Bundle upload notification event from SSE stream
struct BundleUploadEvent: Codable {
    let type: String
    let id: String
    let bundleName: String
    let progressPercent: Double
    let statusMessage: String
    let success: Bool
    let errorMessage: String?
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case type, id
        case bundleName = "bundle_name"
        case progressPercent = "progress_percent"
        case statusMessage = "status_message"
        case success
        case errorMessage = "error_message"
        case timestamp
    }
}

/// Task status notification event from SSE stream
struct TaskStatusEvent: Codable {
    let type: String
    let id: String
    let taskId: String
    let newStatus: String
    let statusMessage: String
    let exitCode: Int?
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case type, id
        case taskId = "task_id"
        case newStatus = "new_status"
        case statusMessage = "status_message"
        case exitCode = "exit_code"
        case timestamp
    }
}

/// Tool registration notification event from SSE stream
struct ToolRegistrationEvent: Codable {
    let type: String
    let id: String
    let toolName: String
    let bundleId: String
    let bundleName: String
    let success: Bool
    let errorMessage: String?
    let totalTools: Int?
    let registeredCount: Int?
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case type, id
        case toolName = "tool_name"
        case bundleId = "bundle_id"
        case bundleName = "bundle_name"
        case success
        case errorMessage = "error_message"
        case totalTools = "total_tools"
        case registeredCount = "registered_count"
        case timestamp
    }
}