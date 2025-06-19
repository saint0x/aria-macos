// Original file: src/proto/session_service.proto

import type * as grpc from '@grpc/grpc-js'
import type { MethodDefinition } from '@grpc/proto-loader'
import type { CreateSessionRequest as _aria_v1_CreateSessionRequest, CreateSessionRequest__Output as _aria_v1_CreateSessionRequest__Output } from '../../aria/v1/CreateSessionRequest';
import type { ExecuteTurnRequest as _aria_v1_ExecuteTurnRequest, ExecuteTurnRequest__Output as _aria_v1_ExecuteTurnRequest__Output } from '../../aria/v1/ExecuteTurnRequest';
import type { GetSessionRequest as _aria_v1_GetSessionRequest, GetSessionRequest__Output as _aria_v1_GetSessionRequest__Output } from '../../aria/v1/GetSessionRequest';
import type { Session as _aria_v1_Session, Session__Output as _aria_v1_Session__Output } from '../../aria/v1/Session';
import type { TurnOutput as _aria_v1_TurnOutput, TurnOutput__Output as _aria_v1_TurnOutput__Output } from '../../aria/v1/TurnOutput';

export interface SessionServiceClient extends grpc.Client {
  CreateSession(argument: _aria_v1_CreateSessionRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  CreateSession(argument: _aria_v1_CreateSessionRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  CreateSession(argument: _aria_v1_CreateSessionRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  CreateSession(argument: _aria_v1_CreateSessionRequest, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  createSession(argument: _aria_v1_CreateSessionRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  createSession(argument: _aria_v1_CreateSessionRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  createSession(argument: _aria_v1_CreateSessionRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  createSession(argument: _aria_v1_CreateSessionRequest, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  
  ExecuteTurn(argument: _aria_v1_ExecuteTurnRequest, metadata: grpc.Metadata, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_TurnOutput__Output>;
  ExecuteTurn(argument: _aria_v1_ExecuteTurnRequest, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_TurnOutput__Output>;
  executeTurn(argument: _aria_v1_ExecuteTurnRequest, metadata: grpc.Metadata, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_TurnOutput__Output>;
  executeTurn(argument: _aria_v1_ExecuteTurnRequest, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_TurnOutput__Output>;
  
  GetSession(argument: _aria_v1_GetSessionRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  GetSession(argument: _aria_v1_GetSessionRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  GetSession(argument: _aria_v1_GetSessionRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  GetSession(argument: _aria_v1_GetSessionRequest, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  getSession(argument: _aria_v1_GetSessionRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  getSession(argument: _aria_v1_GetSessionRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  getSession(argument: _aria_v1_GetSessionRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  getSession(argument: _aria_v1_GetSessionRequest, callback: grpc.requestCallback<_aria_v1_Session__Output>): grpc.ClientUnaryCall;
  
}

export interface SessionServiceHandlers extends grpc.UntypedServiceImplementation {
  CreateSession: grpc.handleUnaryCall<_aria_v1_CreateSessionRequest__Output, _aria_v1_Session>;
  
  ExecuteTurn: grpc.handleServerStreamingCall<_aria_v1_ExecuteTurnRequest__Output, _aria_v1_TurnOutput>;
  
  GetSession: grpc.handleUnaryCall<_aria_v1_GetSessionRequest__Output, _aria_v1_Session>;
  
}

export interface SessionServiceDefinition extends grpc.ServiceDefinition {
  CreateSession: MethodDefinition<_aria_v1_CreateSessionRequest, _aria_v1_Session, _aria_v1_CreateSessionRequest__Output, _aria_v1_Session__Output>
  ExecuteTurn: MethodDefinition<_aria_v1_ExecuteTurnRequest, _aria_v1_TurnOutput, _aria_v1_ExecuteTurnRequest__Output, _aria_v1_TurnOutput__Output>
  GetSession: MethodDefinition<_aria_v1_GetSessionRequest, _aria_v1_Session, _aria_v1_GetSessionRequest__Output, _aria_v1_Session__Output>
}
