// Original file: src/proto/aria.proto

export const MessageRole = {
  MESSAGE_ROLE_UNSPECIFIED: 'MESSAGE_ROLE_UNSPECIFIED',
  SYSTEM: 'SYSTEM',
  USER: 'USER',
  ASSISTANT: 'ASSISTANT',
  TOOL: 'TOOL',
} as const;

export type MessageRole =
  | 'MESSAGE_ROLE_UNSPECIFIED'
  | 0
  | 'SYSTEM'
  | 1
  | 'USER'
  | 2
  | 'ASSISTANT'
  | 3
  | 'TOOL'
  | 4

export type MessageRole__Output = typeof MessageRole[keyof typeof MessageRole]
