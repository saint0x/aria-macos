// Original file: src/proto/session_service.proto


export interface ToolResult {
  'toolName'?: (string);
  'resultJson'?: (string);
  'success'?: (boolean);
  'errorMessage'?: (string);
  '_errorMessage'?: "errorMessage";
}

export interface ToolResult__Output {
  'toolName': (string);
  'resultJson': (string);
  'success': (boolean);
  'errorMessage'?: (string);
  '_errorMessage'?: "errorMessage";
}
