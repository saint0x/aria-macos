// Original file: src/proto/notification_service.proto

import type { TaskStatus as _aria_v1_TaskStatus, TaskStatus__Output as _aria_v1_TaskStatus__Output } from '../../aria/v1/TaskStatus';

export interface TaskStatusEvent {
  'taskId'?: (string);
  'newStatus'?: (_aria_v1_TaskStatus);
  'statusMessage'?: (string);
  'exitCode'?: (number);
  '_exitCode'?: "exitCode";
}

export interface TaskStatusEvent__Output {
  'taskId': (string);
  'newStatus': (_aria_v1_TaskStatus__Output);
  'statusMessage': (string);
  'exitCode'?: (number);
  '_exitCode'?: "exitCode";
}
