// Original file: src/proto/task_service.proto

import type { TaskStatus as _aria_v1_TaskStatus, TaskStatus__Output as _aria_v1_TaskStatus__Output } from '../../aria/v1/TaskStatus';
import type { Timestamp as _google_protobuf_Timestamp, Timestamp__Output as _google_protobuf_Timestamp__Output } from '../../google/protobuf/Timestamp';

export interface Task {
  'id'?: (string);
  'userId'?: (string);
  'sessionId'?: (string);
  'containerId'?: (string);
  'parentTaskId'?: (string);
  'type'?: (string);
  'commandJson'?: (string);
  'environment'?: ({[key: string]: string});
  'timeoutSeconds'?: (number);
  'status'?: (_aria_v1_TaskStatus);
  'createdAt'?: (_google_protobuf_Timestamp | null);
  'startedAt'?: (_google_protobuf_Timestamp | null);
  'completedAt'?: (_google_protobuf_Timestamp | null);
  'exitCode'?: (number);
  'errorMessage'?: (string);
  'progressPercent'?: (number | string);
  'currentOperation'?: (string);
  '_parentTaskId'?: "parentTaskId";
  '_startedAt'?: "startedAt";
  '_completedAt'?: "completedAt";
  '_exitCode'?: "exitCode";
  '_errorMessage'?: "errorMessage";
}

export interface Task__Output {
  'id': (string);
  'userId': (string);
  'sessionId': (string);
  'containerId': (string);
  'parentTaskId'?: (string);
  'type': (string);
  'commandJson': (string);
  'environment': ({[key: string]: string});
  'timeoutSeconds': (number);
  'status': (_aria_v1_TaskStatus__Output);
  'createdAt': (_google_protobuf_Timestamp__Output | null);
  'startedAt'?: (_google_protobuf_Timestamp__Output | null);
  'completedAt'?: (_google_protobuf_Timestamp__Output | null);
  'exitCode'?: (number);
  'errorMessage'?: (string);
  'progressPercent': (number);
  'currentOperation': (string);
  '_parentTaskId'?: "parentTaskId";
  '_startedAt'?: "startedAt";
  '_completedAt'?: "completedAt";
  '_exitCode'?: "exitCode";
  '_errorMessage'?: "errorMessage";
}
