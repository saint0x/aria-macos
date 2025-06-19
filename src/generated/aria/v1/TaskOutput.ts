// Original file: src/proto/task_service.proto

import type { Timestamp as _google_protobuf_Timestamp, Timestamp__Output as _google_protobuf_Timestamp__Output } from '../../google/protobuf/Timestamp';
import type { ProgressUpdate as _aria_v1_ProgressUpdate, ProgressUpdate__Output as _aria_v1_ProgressUpdate__Output } from '../../aria/v1/ProgressUpdate';

export interface TaskOutput {
  'taskId'?: (string);
  'timestamp'?: (_google_protobuf_Timestamp | null);
  'stdoutLine'?: (string);
  'stderrLine'?: (string);
  'progress'?: (_aria_v1_ProgressUpdate | null);
  'output'?: "stdoutLine"|"stderrLine"|"progress";
}

export interface TaskOutput__Output {
  'taskId': (string);
  'timestamp': (_google_protobuf_Timestamp__Output | null);
  'stdoutLine'?: (string);
  'stderrLine'?: (string);
  'progress'?: (_aria_v1_ProgressUpdate__Output | null);
  'output'?: "stdoutLine"|"stderrLine"|"progress";
}
