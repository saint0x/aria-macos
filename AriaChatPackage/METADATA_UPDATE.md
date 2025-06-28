# Swift Client Update for Server Metadata Changes

## Overview
The Swift client has been updated to support the new message metadata provided by the server, enabling semantic message filtering for better UI presentation.

## Changes Made

### 1. New Data Structures

**MessageMetadata** (APIModels.swift:49-53)
```swift
public struct MessageMetadata: Codable, Sendable {
    public let isStatus: Bool
    public let isFinal: Bool
    public let messageType: String
}
```

### 2. Updated Models

**SSEMessageEvent** (APIModels.swift:55-62)
- Added `metadata: MessageMetadata?` field

**Message** (ChatService.swift:258-263)
- Added `metadata: MessageMetadata?` field

**EnhancedStep** (Models.swift:18-32)
- Added `metadata: MessageMetadata?` field

### 3. Enhanced Filtering Logic

**MessageFilterUtils** (MessageFilterUtils.swift:8-36)
- Now uses metadata for semantic filtering when available
- Filter rules:
  - Hide: `metadata.isStatus == true`
  - Show: `metadata.isFinal == true`
  - Falls back to type-based filtering for backward compatibility

### 4. Message Visibility Rules

**Visible in Main Chat:**
- User messages (always)
- Messages with `metadata.isFinal == true`
- Final response events
- Indented tool calls
- Assistant messages without metadata (backward compatibility)

**Hidden from Main Chat:**
- Messages with `metadata.isStatus == true`
- Messages with role `thought`
- Non-indented tool calls

**All messages remain available in the details pane**

## Testing

To test the new filtering:
1. Send a message that triggers multiple server responses
2. Verify only the final response appears in main chat
3. Check that status messages ("Understood...", "Executing...") are hidden
4. Confirm all messages are still accessible in the details pane

## Benefits

1. **Semantic Filtering**: Server controls message visibility through metadata
2. **Cleaner UI**: Only relevant messages shown in main chat
3. **Future-Proof**: Easy to add new message types and filtering rules
4. **Backward Compatible**: Falls back to role-based filtering if metadata is missing

## Example Server Response

```json
{
  "type": "message",
  "id": "msg-123",
  "role": "thought",
  "content": "I'm initiating the task...",
  "created_at": "2024-01-01T00:00:00Z",
  "metadata": {
    "is_status": true,
    "is_final": false,
    "message_type": "status"
  }
}
```

This message would be hidden from main chat due to `is_status: true`.