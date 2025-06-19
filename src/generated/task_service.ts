import type * as grpc from '@grpc/grpc-js';
import type { EnumTypeDefinition, MessageTypeDefinition } from '@grpc/proto-loader';

import type { TaskServiceClient as _aria_v1_TaskServiceClient, TaskServiceDefinition as _aria_v1_TaskServiceDefinition } from './aria/v1/TaskService';

type SubtypeConstructor<Constructor extends new (...args: any) => any, Subtype> = {
  new(...args: ConstructorParameters<Constructor>): Subtype;
};

export interface ProtoGrpcType {
  aria: {
    v1: {
      CancelTaskRequest: MessageTypeDefinition
      CancelTaskResponse: MessageTypeDefinition
      GetTaskRequest: MessageTypeDefinition
      KeyValuePair: MessageTypeDefinition
      LaunchTaskRequest: MessageTypeDefinition
      LaunchTaskResponse: MessageTypeDefinition
      MessageRole: EnumTypeDefinition
      ProgressUpdate: MessageTypeDefinition
      StreamTaskOutputRequest: MessageTypeDefinition
      Task: MessageTypeDefinition
      TaskOutput: MessageTypeDefinition
      TaskService: SubtypeConstructor<typeof grpc.Client, _aria_v1_TaskServiceClient> & { service: _aria_v1_TaskServiceDefinition }
      TaskStatus: EnumTypeDefinition
    }
  }
  google: {
    protobuf: {
      Timestamp: MessageTypeDefinition
    }
  }
}

