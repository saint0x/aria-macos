// Original file: src/proto/session_service.proto

import type { Message as _aria_v1_Message, Message__Output as _aria_v1_Message__Output } from '../../aria/v1/Message';
import type { ToolCall as _aria_v1_ToolCall, ToolCall__Output as _aria_v1_ToolCall__Output } from '../../aria/v1/ToolCall';
import type { ToolResult as _aria_v1_ToolResult, ToolResult__Output as _aria_v1_ToolResult__Output } from '../../aria/v1/ToolResult';

export interface TurnOutput {
  'message'?: (_aria_v1_Message | null);
  'toolCall'?: (_aria_v1_ToolCall | null);
  'toolResult'?: (_aria_v1_ToolResult | null);
  'finalResponse'?: (string);
  'event'?: "message"|"toolCall"|"toolResult"|"finalResponse";
}

export interface TurnOutput__Output {
  'message'?: (_aria_v1_Message__Output | null);
  'toolCall'?: (_aria_v1_ToolCall__Output | null);
  'toolResult'?: (_aria_v1_ToolResult__Output | null);
  'finalResponse'?: (string);
  'event'?: "message"|"toolCall"|"toolResult"|"finalResponse";
}
