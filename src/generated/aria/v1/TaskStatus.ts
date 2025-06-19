// Original file: src/proto/aria.proto

export const TaskStatus = {
  TASK_STATUS_UNSPECIFIED: 'TASK_STATUS_UNSPECIFIED',
  PENDING: 'PENDING',
  RUNNING: 'RUNNING',
  COMPLETED: 'COMPLETED',
  FAILED: 'FAILED',
  CANCELLED: 'CANCELLED',
  TIMEOUT: 'TIMEOUT',
} as const;

export type TaskStatus =
  | 'TASK_STATUS_UNSPECIFIED'
  | 0
  | 'PENDING'
  | 1
  | 'RUNNING'
  | 2
  | 'COMPLETED'
  | 3
  | 'FAILED'
  | 4
  | 'CANCELLED'
  | 5
  | 'TIMEOUT'
  | 6

export type TaskStatus__Output = typeof TaskStatus[keyof typeof TaskStatus]
