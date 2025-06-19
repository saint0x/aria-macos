// Original file: src/proto/notification_service.proto

import type * as grpc from '@grpc/grpc-js'
import type { MethodDefinition } from '@grpc/proto-loader'
import type { Notification as _aria_v1_Notification, Notification__Output as _aria_v1_Notification__Output } from '../../aria/v1/Notification';
import type { StreamNotificationsRequest as _aria_v1_StreamNotificationsRequest, StreamNotificationsRequest__Output as _aria_v1_StreamNotificationsRequest__Output } from '../../aria/v1/StreamNotificationsRequest';

export interface NotificationServiceClient extends grpc.Client {
  StreamNotifications(argument: _aria_v1_StreamNotificationsRequest, metadata: grpc.Metadata, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_Notification__Output>;
  StreamNotifications(argument: _aria_v1_StreamNotificationsRequest, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_Notification__Output>;
  streamNotifications(argument: _aria_v1_StreamNotificationsRequest, metadata: grpc.Metadata, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_Notification__Output>;
  streamNotifications(argument: _aria_v1_StreamNotificationsRequest, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_Notification__Output>;
  
}

export interface NotificationServiceHandlers extends grpc.UntypedServiceImplementation {
  StreamNotifications: grpc.handleServerStreamingCall<_aria_v1_StreamNotificationsRequest__Output, _aria_v1_Notification>;
  
}

export interface NotificationServiceDefinition extends grpc.ServiceDefinition {
  StreamNotifications: MethodDefinition<_aria_v1_StreamNotificationsRequest, _aria_v1_Notification, _aria_v1_StreamNotificationsRequest__Output, _aria_v1_Notification__Output>
}
