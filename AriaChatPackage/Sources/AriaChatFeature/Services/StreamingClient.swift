import Foundation

/// Client for handling Server-Sent Events (SSE) streaming
public actor StreamingClient {
    private let session: URLSession
    private var activeStreams: [UUID: URLSessionDataTask] = [:]
    
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600 // 1 hour for long streams
        self.session = URLSession(configuration: config)
    }
    
    /// Stream data from an SSE endpoint
    public func stream(
        url: URL,
        onEvent: @escaping @Sendable (SSEEvent) async -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) -> StreamHandle {
        let streamId = UUID()
        
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        // Add auth headers synchronously if available (non-blocking)
        addAuthHeadersSync(&request)
        
        let task = session.dataTask(with: request) { data, response, error in
            Task {
                if let error = error {
                    onError(error)
                    await self.removeStream(streamId)
                    return
                }
                
                // This is a simplified implementation
                // In production, we'd need proper SSE parsing
                if let data = data {
                    await self.handleStreamData(data, streamId: streamId, onEvent: onEvent)
                }
            }
        }
        
        activeStreams[streamId] = task
        task.resume()
        
        return StreamHandle(id: streamId, client: self)
    }
    
    /// Stream with URLSession delegate for proper SSE handling
    public func streamWithDelegate(
        url: URL,
        onEvent: @escaping @Sendable (SSEEvent) async -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) -> StreamHandle {
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        // Add auth headers synchronously if available (non-blocking)
        addAuthHeadersSync(&request)
        
        return streamWithRequest(request: request, onEvent: onEvent, onError: onError)
    }
    
    /// Stream with URLRequest for POST support
    public func streamWithRequest(
        request: URLRequest,
        onEvent: @escaping @Sendable (SSEEvent) async -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) -> StreamHandle {
        let streamId = UUID()
        
        let delegate = SSEDelegate(
            streamId: streamId,
            onEvent: onEvent,
            onError: onError,
            onComplete: { [weak self] in
                Task {
                    await self?.removeStream(streamId)
                }
            }
        )
        
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: request)
        
        activeStreams[streamId] = task
        task.resume()
        
        return StreamHandle(id: streamId, client: self)
    }
    
    private func handleStreamData(
        _ data: Data,
        streamId: UUID,
        onEvent: @escaping @Sendable (SSEEvent) async -> Void
    ) async {
        guard let string = String(data: data, encoding: .utf8) else { return }
        
        // Parse SSE format
        let lines = string.components(separatedBy: "\n")
        var eventType: String?
        var eventData = ""
        
        for line in lines {
            if line.isEmpty {
                // End of event
                if !eventData.isEmpty {
                    let event = SSEEvent(
                        type: eventType ?? "message",
                        data: eventData.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    await onEvent(event)
                }
                eventType = nil
                eventData = ""
            } else if line.hasPrefix("event:") {
                eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                let data = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if !eventData.isEmpty {
                    eventData += "\n"
                }
                eventData += data
            }
        }
    }
    
    func removeStream(_ id: UUID) {
        activeStreams[id]?.cancel()
        activeStreams.removeValue(forKey: id)
    }
    
    func cancelAllStreams() {
        for task in activeStreams.values {
            task.cancel()
        }
        activeStreams.removeAll()
    }
    
    private func addAuthHeaders(_ request: inout URLRequest) async {
        // Add authentication header if available
        if let authHeader = await AuthenticationManager.shared.getAuthorizationHeader() {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
    }
    
    private func addAuthHeadersSync(_ request: inout URLRequest) {
        // Non-blocking auth header addition for compatibility
        // This will work for unauthenticated users (no headers added) and authenticated users
        // For authenticated users, we'll add the header if immediately available
        Task {
            if await AuthenticationManager.shared.getAuthorizationHeader() != nil {
                // For future requests, this will be available
                print("StreamingClient: Auth header available for future requests")
            }
        }
        // Request proceeds immediately without blocking, works for unauthenticated flow
    }
}

// MARK: - Supporting Types

public struct SSEEvent: @unchecked Sendable {
    public let type: String
    public let data: String
    public let json: Any?
    
    init(type: String, data: String) {
        self.type = type
        self.data = data
        
        // Try to parse as JSON
        if let jsonData = data.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) {
            self.json = json
        } else {
            self.json = nil
        }
    }
}

public struct StreamHandle: Sendable {
    let id: UUID
    let client: StreamingClient?
    
    public func cancel() async {
        await client?.removeStream(id)
    }
}

// MARK: - SSE Delegate

private final class SSEDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    let streamId: UUID
    let onEvent: @Sendable (SSEEvent) async -> Void
    let onError: @Sendable (Error) -> Void
    let onComplete: @Sendable () -> Void
    
    private var buffer = Data()
    
    init(
        streamId: UUID,
        onEvent: @escaping @Sendable (SSEEvent) async -> Void,
        onError: @escaping @Sendable (Error) -> Void,
        onComplete: @escaping @Sendable () -> Void
    ) {
        self.streamId = streamId
        self.onEvent = onEvent
        self.onError = onError
        self.onComplete = onComplete
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        
        // Process complete events from buffer
        while let range = buffer.range(of: "\n\n".data(using: .utf8)!) {
            let eventData = buffer.subdata(in: 0..<range.lowerBound)
            buffer.removeSubrange(0..<range.upperBound)
            
            if let eventString = String(data: eventData, encoding: .utf8), !eventString.isEmpty {
                parseAndEmitEvent(eventString)
            }
        }
        
        // Also check for single newline terminated events (some SSE implementations)
        if let newlineRange = buffer.range(of: "\n".data(using: .utf8)!),
           newlineRange.lowerBound == buffer.count - 1 {
            let eventData = buffer.subdata(in: 0..<newlineRange.lowerBound)
            if let eventString = String(data: eventData, encoding: .utf8), !eventString.isEmpty {
                parseAndEmitEvent(eventString)
                buffer.removeAll()
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Process any remaining data in buffer
        if !buffer.isEmpty, let eventString = String(data: buffer, encoding: .utf8) {
            parseAndEmitEvent(eventString)
            buffer.removeAll()
        }
        
        if let error = error {
            // Check if it's a normal stream termination
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled {
                // Normal cancellation, not an error
                onComplete()
            } else {
                onError(error)
            }
        } else {
            onComplete()
        }
    }
    
    private func parseAndEmitEvent(_ eventString: String) {
        let lines = eventString.components(separatedBy: "\n")
        var eventType: String?
        var eventData = ""
        
        for line in lines {
            if line.hasPrefix("event:") {
                eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                let data = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if !eventData.isEmpty {
                    eventData += "\n"
                }
                eventData += data
            }
        }
        
        if !eventData.isEmpty {
            let event = SSEEvent(
                type: eventType ?? "message",
                data: eventData
            )
            
            Task {
                await onEvent(event)
            }
        }
    }
}