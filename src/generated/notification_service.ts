import type * as grpc from '@grpc/grpc-js';
import type { EnumTypeDefinition, MessageTypeDefinition } from '@grpc/proto-loader';

import type { NotificationServiceClient as _aria_v1_NotificationServiceClient, NotificationServiceDefinition as _aria_v1_NotificationServiceDefinition } from './aria/v1/NotificationService';

type SubtypeConstructor<Constructor extends new (...args: any) => any, Subtype> = {
  new(...args: ConstructorParameters<Constructor>): Subtype;
};

export interface ProtoGrpcType {
  aria: {
    v1: {
      BundleUploadEvent: MessageTypeDefinition
      KeyValuePair: MessageTypeDefinition
      MessageRole: EnumTypeDefinition
      Notification: MessageTypeDefinition
      NotificationService: SubtypeConstructor<typeof grpc.Client, _aria_v1_NotificationServiceClient> & { service: _aria_v1_NotificationServiceDefinition }
      StreamNotificationsRequest: MessageTypeDefinition
      TaskStatus: EnumTypeDefinition
      TaskStatusEvent: MessageTypeDefinition
    }
  }
  google: {
    protobuf: {
      Timestamp: MessageTypeDefinition
    }
  }
}

