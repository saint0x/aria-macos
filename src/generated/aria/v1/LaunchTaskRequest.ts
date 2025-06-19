// Original file: src/proto/task_service.proto


export interface LaunchTaskRequest {
  'sessionId'?: (string);
  'type'?: (string);
  'commandJson'?: (string);
  'environment'?: ({[key: string]: string});
  'timeoutSeconds'?: (number);
}

export interface LaunchTaskRequest__Output {
  'sessionId': (string);
  'type': (string);
  'commandJson': (string);
  'environment': ({[key: string]: string});
  'timeoutSeconds': (number);
}
