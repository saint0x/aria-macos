// Original file: src/proto/notification_service.proto

import type { Timestamp as _google_protobuf_Timestamp, Timestamp__Output as _google_protobuf_Timestamp__Output } from '../../google/protobuf/Timestamp';
import type { BundleUploadEvent as _aria_v1_BundleUploadEvent, BundleUploadEvent__Output as _aria_v1_BundleUploadEvent__Output } from '../../aria/v1/BundleUploadEvent';
import type { TaskStatusEvent as _aria_v1_TaskStatusEvent, TaskStatusEvent__Output as _aria_v1_TaskStatusEvent__Output } from '../../aria/v1/TaskStatusEvent';

export interface Notification {
  'id'?: (string);
  'timestamp'?: (_google_protobuf_Timestamp | null);
  'bundleUpload'?: (_aria_v1_BundleUploadEvent | null);
  'taskStatus'?: (_aria_v1_TaskStatusEvent | null);
  'eventPayload'?: "bundleUpload"|"taskStatus";
}

export interface Notification__Output {
  'id': (string);
  'timestamp': (_google_protobuf_Timestamp__Output | null);
  'bundleUpload'?: (_aria_v1_BundleUploadEvent__Output | null);
  'taskStatus'?: (_aria_v1_TaskStatusEvent__Output | null);
  'eventPayload'?: "bundleUpload"|"taskStatus";
}
