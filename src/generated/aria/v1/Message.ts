// Original file: src/proto/session_service.proto

import type { MessageRole as _aria_v1_MessageRole, MessageRole__Output as _aria_v1_MessageRole__Output } from '../../aria/v1/MessageRole';
import type { Timestamp as _google_protobuf_Timestamp, Timestamp__Output as _google_protobuf_Timestamp__Output } from '../../google/protobuf/Timestamp';

export interface Message {
  'id'?: (string);
  'role'?: (_aria_v1_MessageRole);
  'content'?: (string);
  'createdAt'?: (_google_protobuf_Timestamp | null);
}

export interface Message__Output {
  'id': (string);
  'role': (_aria_v1_MessageRole__Output);
  'content': (string);
  'createdAt': (_google_protobuf_Timestamp__Output | null);
}
