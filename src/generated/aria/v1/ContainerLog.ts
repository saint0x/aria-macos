// Original file: src/proto/container_service.proto

import type { Timestamp as _google_protobuf_Timestamp, Timestamp__Output as _google_protobuf_Timestamp__Output } from '../../google/protobuf/Timestamp';

// Original file: src/proto/container_service.proto

export const _aria_v1_ContainerLog_Stream = {
  STREAM_UNSPECIFIED: 'STREAM_UNSPECIFIED',
  STDOUT: 'STDOUT',
  STDERR: 'STDERR',
} as const;

export type _aria_v1_ContainerLog_Stream =
  | 'STREAM_UNSPECIFIED'
  | 0
  | 'STDOUT'
  | 1
  | 'STDERR'
  | 2

export type _aria_v1_ContainerLog_Stream__Output = typeof _aria_v1_ContainerLog_Stream[keyof typeof _aria_v1_ContainerLog_Stream]

export interface ContainerLog {
  'line'?: (string);
  'stream'?: (_aria_v1_ContainerLog_Stream);
  'timestamp'?: (_google_protobuf_Timestamp | null);
}

export interface ContainerLog__Output {
  'line': (string);
  'stream': (_aria_v1_ContainerLog_Stream__Output);
  'timestamp': (_google_protobuf_Timestamp__Output | null);
}
