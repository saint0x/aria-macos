// Original file: src/proto/container_service.proto

import type { TaskStatus as _aria_v1_TaskStatus, TaskStatus__Output as _aria_v1_TaskStatus__Output } from '../../aria/v1/TaskStatus';
import type { Timestamp as _google_protobuf_Timestamp, Timestamp__Output as _google_protobuf_Timestamp__Output } from '../../google/protobuf/Timestamp';

export interface Container {
  'id'?: (string);
  'userId'?: (string);
  'sessionId'?: (string);
  'name'?: (string);
  'imagePath'?: (string);
  'status'?: (_aria_v1_TaskStatus);
  'createdAt'?: (_google_protobuf_Timestamp | null);
  '_sessionId'?: "sessionId";
}

export interface Container__Output {
  'id': (string);
  'userId': (string);
  'sessionId'?: (string);
  'name': (string);
  'imagePath': (string);
  'status': (_aria_v1_TaskStatus__Output);
  'createdAt': (_google_protobuf_Timestamp__Output | null);
  '_sessionId'?: "sessionId";
}
