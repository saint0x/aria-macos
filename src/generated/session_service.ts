import type * as grpc from '@grpc/grpc-js';
import type { EnumTypeDefinition, MessageTypeDefinition } from '@grpc/proto-loader';

import type { SessionServiceClient as _aria_v1_SessionServiceClient, SessionServiceDefinition as _aria_v1_SessionServiceDefinition } from './aria/v1/SessionService';

type SubtypeConstructor<Constructor extends new (...args: any) => any, Subtype> = {
  new(...args: ConstructorParameters<Constructor>): Subtype;
};

export interface ProtoGrpcType {
  aria: {
    v1: {
      CreateSessionRequest: MessageTypeDefinition
      ExecuteTurnRequest: MessageTypeDefinition
      GetSessionRequest: MessageTypeDefinition
      KeyValuePair: MessageTypeDefinition
      Message: MessageTypeDefinition
      MessageRole: EnumTypeDefinition
      Session: MessageTypeDefinition
      SessionService: SubtypeConstructor<typeof grpc.Client, _aria_v1_SessionServiceClient> & { service: _aria_v1_SessionServiceDefinition }
      TaskStatus: EnumTypeDefinition
      ToolCall: MessageTypeDefinition
      ToolResult: MessageTypeDefinition
      TurnOutput: MessageTypeDefinition
    }
  }
  google: {
    protobuf: {
      Timestamp: MessageTypeDefinition
    }
  }
}

