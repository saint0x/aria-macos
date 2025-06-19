import type * as grpc from '@grpc/grpc-js';
import type { EnumTypeDefinition, MessageTypeDefinition } from '@grpc/proto-loader';

import type { ContainerServiceClient as _aria_v1_ContainerServiceClient, ContainerServiceDefinition as _aria_v1_ContainerServiceDefinition } from './aria/v1/ContainerService';

type SubtypeConstructor<Constructor extends new (...args: any) => any, Subtype> = {
  new(...args: ConstructorParameters<Constructor>): Subtype;
};

export interface ProtoGrpcType {
  aria: {
    v1: {
      Container: MessageTypeDefinition
      ContainerLog: MessageTypeDefinition
      ContainerService: SubtypeConstructor<typeof grpc.Client, _aria_v1_ContainerServiceClient> & { service: _aria_v1_ContainerServiceDefinition }
      CreateContainerRequest: MessageTypeDefinition
      GetContainerRequest: MessageTypeDefinition
      KeyValuePair: MessageTypeDefinition
      ListContainersRequest: MessageTypeDefinition
      ListContainersResponse: MessageTypeDefinition
      MessageRole: EnumTypeDefinition
      RemoveContainerRequest: MessageTypeDefinition
      RemoveContainerResponse: MessageTypeDefinition
      StartContainerRequest: MessageTypeDefinition
      StartContainerResponse: MessageTypeDefinition
      StopContainerRequest: MessageTypeDefinition
      StopContainerResponse: MessageTypeDefinition
      StreamContainerLogsRequest: MessageTypeDefinition
      TaskStatus: EnumTypeDefinition
    }
  }
  google: {
    protobuf: {
      Timestamp: MessageTypeDefinition
    }
  }
}

