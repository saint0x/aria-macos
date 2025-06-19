// Original file: src/proto/container_service.proto

import type { Timestamp as _google_protobuf_Timestamp, Timestamp__Output as _google_protobuf_Timestamp__Output } from '../../google/protobuf/Timestamp';

export interface StreamContainerLogsRequest {
  'containerId'?: (string);
  'follow'?: (boolean);
  'since'?: (_google_protobuf_Timestamp | null);
  '_since'?: "since";
}

export interface StreamContainerLogsRequest__Output {
  'containerId': (string);
  'follow': (boolean);
  'since'?: (_google_protobuf_Timestamp__Output | null);
  '_since'?: "since";
}
