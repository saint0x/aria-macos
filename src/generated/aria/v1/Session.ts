// Original file: src/proto/session_service.proto

import type { Timestamp as _google_protobuf_Timestamp, Timestamp__Output as _google_protobuf_Timestamp__Output } from '../../google/protobuf/Timestamp';

export interface Session {
  'id'?: (string);
  'userId'?: (string);
  'createdAt'?: (_google_protobuf_Timestamp | null);
  'contextData'?: ({[key: string]: string});
  'status'?: (string);
}

export interface Session__Output {
  'id': (string);
  'userId': (string);
  'createdAt': (_google_protobuf_Timestamp__Output | null);
  'contextData': ({[key: string]: string});
  'status': (string);
}
