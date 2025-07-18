import Foundation

@MainActor
public class ObservabilityService: ObservableObject {
    public static let shared = ObservabilityService()
    
    @Published public var logs: [LogEntry] = []
    @Published public var metrics: MetricsData?
    @Published public var health: HealthData?
    @Published public var isStreamingLogs = false
    @Published public var isLoadingLogs = false
    @Published public var isLoadingMetrics = false
    @Published public var isLoadingHealth = false
    @Published public var logsError: Error?
    @Published public var metricsError: Error?
    @Published public var healthError: Error?
    
    private let apiClient = RESTAPIClient.shared
    private var logStreamTask: Task<Void, Never>?
    
    private init() {}
    
    // MARK: - Logs
    
    public func loadRecentLogs(
        limit: Int? = 100,
        level: String? = nil,
        component: String? = nil,
        sessionId: String? = nil,
        since: String? = nil,
        until: String? = nil,
        refresh: Bool = false
    ) async throws {
        if isLoadingLogs && !refresh {
            return
        }
        
        isLoadingLogs = true
        logsError = nil
        
        do {
            let queryParams = APIEndpoints.QueryParams.logsRecent(
                limit: limit,
                level: level,
                component: component,
                sessionId: sessionId,
                since: since,
                until: until
            )
            
            let response: RecentLogsResponse = try await apiClient.get(
                endpoint: APIEndpoints.logsRecent,
                queryParams: queryParams
            )
            
            self.logs = response.data.logs
            print("ObservabilityService: Loaded \(logs.count) log entries")
            
        } catch {
            print("ObservabilityService: Error loading logs: \(error)")
            self.logsError = error
            throw error
        }
        
        isLoadingLogs = false
    }
    
    public func startLogStreaming(
        filterComponents: [String]? = nil,
        sessionId: String? = nil
    ) {
        stopLogStreaming()
        
        isStreamingLogs = true
        logsError = nil
        
        logStreamTask = Task {
            do {
                let queryParams = APIEndpoints.QueryParams.logsStream(
                    filterComponents: filterComponents,
                    sessionId: sessionId
                )
                
                try await apiClient.streamSSE(
                    endpoint: APIEndpoints.logsStream,
                    queryParams: queryParams
                ) { [weak self] eventData in
                    await MainActor.run {
                        self?.handleLogStreamEvent(eventData)
                    }
                }
                
            } catch {
                await MainActor.run {
                    print("ObservabilityService: Log streaming error: \(error)")
                    self.logsError = error
                    self.isStreamingLogs = false
                }
            }
        }
    }
    
    public func stopLogStreaming() {
        logStreamTask?.cancel()
        logStreamTask = nil
        isStreamingLogs = false
    }
    
    private func handleLogStreamEvent(_ eventData: Data) {
        do {
            let streamEvent = try JSONDecoder().decode(LogStreamEvent.self, from: eventData)
            
            if streamEvent.type == "log" {
                logs.insert(streamEvent.entry, at: 0)
                
                if logs.count > 1000 {
                    logs.removeLast(logs.count - 1000)
                }
            }
            
        } catch {
            print("ObservabilityService: Error parsing log stream event: \(error)")
        }
    }
    
    // MARK: - Metrics
    
    public func loadMetrics(refresh: Bool = false) async throws {
        if isLoadingMetrics && !refresh {
            return
        }
        
        isLoadingMetrics = true
        metricsError = nil
        
        do {
            let response: MetricsResponse = try await apiClient.get(
                endpoint: APIEndpoints.metrics
            )
            
            self.metrics = response.data
            print("ObservabilityService: Loaded metrics for \(response.data.timestamp)")
            
        } catch {
            print("ObservabilityService: Error loading metrics: \(error)")
            self.metricsError = error
            throw error
        }
        
        isLoadingMetrics = false
    }
    
    // MARK: - Health
    
    public func loadHealth(refresh: Bool = false) async throws {
        if isLoadingHealth && !refresh {
            return
        }
        
        isLoadingHealth = true
        healthError = nil
        
        do {
            let response: HealthResponse = try await apiClient.get(
                endpoint: APIEndpoints.health
            )
            
            self.health = response.data
            print("ObservabilityService: Health status: \(response.data.status)")
            
        } catch {
            print("ObservabilityService: Error loading health: \(error)")
            self.healthError = error
            throw error
        }
        
        isLoadingHealth = false
    }
    
    // MARK: - Utility Methods
    
    public func getLogsByLevel(_ level: String) -> [LogEntry] {
        return logs.filter { $0.level.lowercased() == level.lowercased() }
    }
    
    public func getLogsByComponent(_ component: String) -> [LogEntry] {
        return logs.filter { $0.metadata.component.lowercased() == component.lowercased() }
    }
    
    public func getErrorLogs() -> [LogEntry] {
        return getLogsByLevel("error")
    }
    
    public func getWarningLogs() -> [LogEntry] {
        return getLogsByLevel("warn") + getLogsByLevel("warning")
    }
    
    public func getInfoLogs() -> [LogEntry] {
        return getLogsByLevel("info")
    }
    
    public func getLogComponents() -> [String] {
        return Array(Set(logs.map { $0.metadata.component })).sorted()
    }
    
    public func searchLogs(_ query: String) -> [LogEntry] {
        let lowercaseQuery = query.lowercased()
        return logs.filter { log in
            log.message.lowercased().contains(lowercaseQuery) ||
            log.target.lowercased().contains(lowercaseQuery) ||
            log.metadata.component.lowercased().contains(lowercaseQuery)
        }
    }
    
    public func isSystemHealthy() -> Bool {
        return health?.status.lowercased() == "healthy"
    }
    
    public func getUnhealthyComponents() -> [String: ComponentHealth] {
        guard let health = health else { return [:] }
        return health.components.filter { $0.value.status.lowercased() != "healthy" }
    }
    
    public func getSystemUptime() -> TimeInterval? {
        guard let health = health else { return nil }
        return TimeInterval(health.uptimeSeconds)
    }
    
    // MARK: - Real-time Updates
    
    public func startPeriodicMetricsUpdate(interval: TimeInterval = 30.0) {
        Task {
            while !Task.isCancelled {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                
                if !Task.isCancelled {
                    try? await loadMetrics(refresh: true)
                }
            }
        }
    }
    
    public func startPeriodicHealthCheck(interval: TimeInterval = 60.0) {
        Task {
            while !Task.isCancelled {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                
                if !Task.isCancelled {
                    try? await loadHealth(refresh: true)
                }
            }
        }
    }
    
    // MARK: - Refresh All
    
    public func refreshAll() async throws {
        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.loadRecentLogs(refresh: true)
            }
            
            group.addTask {
                try await self.loadMetrics(refresh: true)
            }
            
            group.addTask {
                try await self.loadHealth(refresh: true)
            }
            
            for await _ in group {}
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopLogStreaming()
    }
}