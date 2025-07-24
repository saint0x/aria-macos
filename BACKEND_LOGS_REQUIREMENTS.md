# Backend Requirements for Tool Usage Logs

## Overview

The frontend logs page is fully implemented with comprehensive UI, real-time streaming, filtering, and data models. The backend needs to emit structured log events for tool operations to populate the logs interface.

## Current Implementation Status

✅ **Frontend Complete:**
- Real-time log streaming via `/api/v1/logs/stream` (SSE)
- Comprehensive filtering UI (level, component, session, time range)
- Glassmorphic design with expandable log entries
- Auto-scrolling with memory management (250 log limit)
- Full error handling and loading states

❌ **Backend Missing:**
- Tool usage log events
- Structured metadata for tool operations
- Performance tracking and analytics

## Required Log Event Structure

### Base Log Entry Format
```json
{
  "id": "log_entry_uuid",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "level": "INFO|WARN|ERROR",
  "message": "Human-readable log message",
  "target": "tool_manager",
  "sessionId": "session_uuid",
  "userId": "user_uuid",
  "fields": {
    // Tool-specific fields (see below)
  },
  "metadata": {
    "component": "tool_execution",
    "operation": "tool_call|tool_success|tool_error|tool_timeout",
    "durationMs": 1500
  }
}
```

### Tool-Specific Fields
The `fields` object should contain tool-specific metadata:

```json
{
  "toolName": "bash|grep|edit|read|write|glob|task",
  "toolOperation": "call|success|error|timeout",
  "toolParameters": "sanitized_hash_of_parameters", 
  "toolResult": "success|error_message|truncated_output",
  "toolExitCode": 0,
  "toolDuration": 1500,
  "sessionId": "session_uuid",
  "userId": "user_uuid",
  "errorType": "timeout|permission_denied|file_not_found|...",
  "resultSize": 1024
}
```

## Required Logging Points

### 1. Tool Invocation
Log when any tool is called:
```json
{
  "level": "INFO",
  "message": "Tool invoked: bash with command 'ls -la'",
  "fields": {
    "toolName": "bash",
    "toolOperation": "call",
    "toolParameters": "hash_of_sanitized_params",
    "sessionId": "session_123"
  },
  "metadata": {
    "component": "tool_execution",
    "operation": "tool_call"
  }
}
```

### 2. Tool Success
Log successful completion:
```json
{
  "level": "INFO", 
  "message": "Tool completed successfully: bash",
  "fields": {
    "toolName": "bash",
    "toolOperation": "success",
    "toolResult": "success",
    "toolExitCode": 0,
    "toolDuration": 1200,
    "resultSize": 512
  },
  "metadata": {
    "component": "tool_execution",
    "operation": "tool_success",
    "durationMs": 1200
  }
}
```

### 3. Tool Error
Log failures with detailed error information:
```json
{
  "level": "ERROR",
  "message": "Tool execution failed: bash - Permission denied",
  "fields": {
    "toolName": "bash", 
    "toolOperation": "error",
    "toolResult": "Permission denied accessing /restricted/path",
    "toolExitCode": 1,
    "errorType": "permission_denied",
    "toolDuration": 50
  },
  "metadata": {
    "component": "tool_execution",
    "operation": "tool_error",
    "durationMs": 50
  }
}
```

### 4. Tool Timeout
Log when tools exceed time limits:
```json
{
  "level": "WARN",
  "message": "Tool execution timed out: long_running_script",
  "fields": {
    "toolName": "bash",
    "toolOperation": "timeout", 
    "toolResult": "Execution timed out after 30000ms",
    "errorType": "timeout",
    "toolDuration": 30000
  },
  "metadata": {
    "component": "tool_execution",
    "operation": "tool_timeout",
    "durationMs": 30000
  }
}
```

## Security Considerations

### Parameter Sanitization
- Never log sensitive parameters (passwords, keys, tokens)
- Hash or sanitize file paths and command arguments
- Truncate large outputs to reasonable size limits
- Remove any personally identifiable information

### Example Sanitization:
```json
// Original parameters
{
  "command": "curl -H 'Authorization: Bearer secret123' https://api.example.com/user/john.doe@email.com"
}

// Sanitized for logging
{
  "toolParameters": "curl_request_hash_abc123",
  "commandType": "curl",
  "targetDomain": "api.example.com"
}
```

## Performance Requirements

### Log Volume Management
- Implement log level filtering at source
- Use structured logging with consistent field names
- Batch log writes for high-frequency operations
- Consider async logging for performance-critical tools

### Real-time Streaming
- Emit log events immediately via existing SSE stream
- No buffering delay for tool events
- Maintain chronological order across concurrent tool executions

## Analytics Integration

### Metrics to Track
- Tool usage frequency by type
- Tool success/failure rates
- Tool performance trends (duration analysis)
- Error pattern analysis
- User tool preferences

### Aggregation Points
Connect to existing `/api/v1/metrics` endpoint for:
- `toolExecutions` count in RuntimeMetrics
- Tool-specific performance data
- Error rate calculations
- Usage analytics by session/user

## Implementation Checklist

- [ ] Add tool logging to core tool execution pipeline
- [ ] Implement parameter sanitization logic
- [ ] Configure log level filtering for tool events
- [ ] Test real-time streaming of tool logs
- [ ] Verify log entry structure matches frontend models
- [ ] Add tool metrics to existing metrics endpoint
- [ ] Implement log retention policies for tool events
- [ ] Add performance monitoring for logging overhead

## Testing Verification

The frontend can be tested immediately once backend implements these log events:

1. Execute various tools (bash, grep, edit, etc.)
2. Verify logs appear in real-time in the UI
3. Test filtering by tool name, session, and time range
4. Confirm error logs show proper error details
5. Validate performance metrics are captured
6. Test log retention and cleanup

## Notes

- The existing logs page UI is production-ready and requires no changes
- All data models and API endpoints are already implemented
- The real-time streaming infrastructure is fully functional
- This is purely a backend implementation task