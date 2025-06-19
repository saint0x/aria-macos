// Original file: src/proto/container_service.proto

import type * as grpc from '@grpc/grpc-js'
import type { MethodDefinition } from '@grpc/proto-loader'
import type { Container as _aria_v1_Container, Container__Output as _aria_v1_Container__Output } from '../../aria/v1/Container';
import type { ContainerLog as _aria_v1_ContainerLog, ContainerLog__Output as _aria_v1_ContainerLog__Output } from '../../aria/v1/ContainerLog';
import type { CreateContainerRequest as _aria_v1_CreateContainerRequest, CreateContainerRequest__Output as _aria_v1_CreateContainerRequest__Output } from '../../aria/v1/CreateContainerRequest';
import type { GetContainerRequest as _aria_v1_GetContainerRequest, GetContainerRequest__Output as _aria_v1_GetContainerRequest__Output } from '../../aria/v1/GetContainerRequest';
import type { ListContainersRequest as _aria_v1_ListContainersRequest, ListContainersRequest__Output as _aria_v1_ListContainersRequest__Output } from '../../aria/v1/ListContainersRequest';
import type { ListContainersResponse as _aria_v1_ListContainersResponse, ListContainersResponse__Output as _aria_v1_ListContainersResponse__Output } from '../../aria/v1/ListContainersResponse';
import type { RemoveContainerRequest as _aria_v1_RemoveContainerRequest, RemoveContainerRequest__Output as _aria_v1_RemoveContainerRequest__Output } from '../../aria/v1/RemoveContainerRequest';
import type { RemoveContainerResponse as _aria_v1_RemoveContainerResponse, RemoveContainerResponse__Output as _aria_v1_RemoveContainerResponse__Output } from '../../aria/v1/RemoveContainerResponse';
import type { StartContainerRequest as _aria_v1_StartContainerRequest, StartContainerRequest__Output as _aria_v1_StartContainerRequest__Output } from '../../aria/v1/StartContainerRequest';
import type { StartContainerResponse as _aria_v1_StartContainerResponse, StartContainerResponse__Output as _aria_v1_StartContainerResponse__Output } from '../../aria/v1/StartContainerResponse';
import type { StopContainerRequest as _aria_v1_StopContainerRequest, StopContainerRequest__Output as _aria_v1_StopContainerRequest__Output } from '../../aria/v1/StopContainerRequest';
import type { StopContainerResponse as _aria_v1_StopContainerResponse, StopContainerResponse__Output as _aria_v1_StopContainerResponse__Output } from '../../aria/v1/StopContainerResponse';
import type { StreamContainerLogsRequest as _aria_v1_StreamContainerLogsRequest, StreamContainerLogsRequest__Output as _aria_v1_StreamContainerLogsRequest__Output } from '../../aria/v1/StreamContainerLogsRequest';

export interface ContainerServiceClient extends grpc.Client {
  CreateContainer(argument: _aria_v1_CreateContainerRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  CreateContainer(argument: _aria_v1_CreateContainerRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  CreateContainer(argument: _aria_v1_CreateContainerRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  CreateContainer(argument: _aria_v1_CreateContainerRequest, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  createContainer(argument: _aria_v1_CreateContainerRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  createContainer(argument: _aria_v1_CreateContainerRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  createContainer(argument: _aria_v1_CreateContainerRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  createContainer(argument: _aria_v1_CreateContainerRequest, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  
  GetContainer(argument: _aria_v1_GetContainerRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  GetContainer(argument: _aria_v1_GetContainerRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  GetContainer(argument: _aria_v1_GetContainerRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  GetContainer(argument: _aria_v1_GetContainerRequest, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  getContainer(argument: _aria_v1_GetContainerRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  getContainer(argument: _aria_v1_GetContainerRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  getContainer(argument: _aria_v1_GetContainerRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  getContainer(argument: _aria_v1_GetContainerRequest, callback: grpc.requestCallback<_aria_v1_Container__Output>): grpc.ClientUnaryCall;
  
  ListContainers(argument: _aria_v1_ListContainersRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_ListContainersResponse__Output>): grpc.ClientUnaryCall;
  ListContainers(argument: _aria_v1_ListContainersRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_ListContainersResponse__Output>): grpc.ClientUnaryCall;
  ListContainers(argument: _aria_v1_ListContainersRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_ListContainersResponse__Output>): grpc.ClientUnaryCall;
  ListContainers(argument: _aria_v1_ListContainersRequest, callback: grpc.requestCallback<_aria_v1_ListContainersResponse__Output>): grpc.ClientUnaryCall;
  listContainers(argument: _aria_v1_ListContainersRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_ListContainersResponse__Output>): grpc.ClientUnaryCall;
  listContainers(argument: _aria_v1_ListContainersRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_ListContainersResponse__Output>): grpc.ClientUnaryCall;
  listContainers(argument: _aria_v1_ListContainersRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_ListContainersResponse__Output>): grpc.ClientUnaryCall;
  listContainers(argument: _aria_v1_ListContainersRequest, callback: grpc.requestCallback<_aria_v1_ListContainersResponse__Output>): grpc.ClientUnaryCall;
  
  RemoveContainer(argument: _aria_v1_RemoveContainerRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_RemoveContainerResponse__Output>): grpc.ClientUnaryCall;
  RemoveContainer(argument: _aria_v1_RemoveContainerRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_RemoveContainerResponse__Output>): grpc.ClientUnaryCall;
  RemoveContainer(argument: _aria_v1_RemoveContainerRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_RemoveContainerResponse__Output>): grpc.ClientUnaryCall;
  RemoveContainer(argument: _aria_v1_RemoveContainerRequest, callback: grpc.requestCallback<_aria_v1_RemoveContainerResponse__Output>): grpc.ClientUnaryCall;
  removeContainer(argument: _aria_v1_RemoveContainerRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_RemoveContainerResponse__Output>): grpc.ClientUnaryCall;
  removeContainer(argument: _aria_v1_RemoveContainerRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_RemoveContainerResponse__Output>): grpc.ClientUnaryCall;
  removeContainer(argument: _aria_v1_RemoveContainerRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_RemoveContainerResponse__Output>): grpc.ClientUnaryCall;
  removeContainer(argument: _aria_v1_RemoveContainerRequest, callback: grpc.requestCallback<_aria_v1_RemoveContainerResponse__Output>): grpc.ClientUnaryCall;
  
  StartContainer(argument: _aria_v1_StartContainerRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_StartContainerResponse__Output>): grpc.ClientUnaryCall;
  StartContainer(argument: _aria_v1_StartContainerRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_StartContainerResponse__Output>): grpc.ClientUnaryCall;
  StartContainer(argument: _aria_v1_StartContainerRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_StartContainerResponse__Output>): grpc.ClientUnaryCall;
  StartContainer(argument: _aria_v1_StartContainerRequest, callback: grpc.requestCallback<_aria_v1_StartContainerResponse__Output>): grpc.ClientUnaryCall;
  startContainer(argument: _aria_v1_StartContainerRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_StartContainerResponse__Output>): grpc.ClientUnaryCall;
  startContainer(argument: _aria_v1_StartContainerRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_StartContainerResponse__Output>): grpc.ClientUnaryCall;
  startContainer(argument: _aria_v1_StartContainerRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_StartContainerResponse__Output>): grpc.ClientUnaryCall;
  startContainer(argument: _aria_v1_StartContainerRequest, callback: grpc.requestCallback<_aria_v1_StartContainerResponse__Output>): grpc.ClientUnaryCall;
  
  StopContainer(argument: _aria_v1_StopContainerRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_StopContainerResponse__Output>): grpc.ClientUnaryCall;
  StopContainer(argument: _aria_v1_StopContainerRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_StopContainerResponse__Output>): grpc.ClientUnaryCall;
  StopContainer(argument: _aria_v1_StopContainerRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_StopContainerResponse__Output>): grpc.ClientUnaryCall;
  StopContainer(argument: _aria_v1_StopContainerRequest, callback: grpc.requestCallback<_aria_v1_StopContainerResponse__Output>): grpc.ClientUnaryCall;
  stopContainer(argument: _aria_v1_StopContainerRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_StopContainerResponse__Output>): grpc.ClientUnaryCall;
  stopContainer(argument: _aria_v1_StopContainerRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_StopContainerResponse__Output>): grpc.ClientUnaryCall;
  stopContainer(argument: _aria_v1_StopContainerRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_StopContainerResponse__Output>): grpc.ClientUnaryCall;
  stopContainer(argument: _aria_v1_StopContainerRequest, callback: grpc.requestCallback<_aria_v1_StopContainerResponse__Output>): grpc.ClientUnaryCall;
  
  StreamContainerLogs(argument: _aria_v1_StreamContainerLogsRequest, metadata: grpc.Metadata, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_ContainerLog__Output>;
  StreamContainerLogs(argument: _aria_v1_StreamContainerLogsRequest, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_ContainerLog__Output>;
  streamContainerLogs(argument: _aria_v1_StreamContainerLogsRequest, metadata: grpc.Metadata, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_ContainerLog__Output>;
  streamContainerLogs(argument: _aria_v1_StreamContainerLogsRequest, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_ContainerLog__Output>;
  
}

export interface ContainerServiceHandlers extends grpc.UntypedServiceImplementation {
  CreateContainer: grpc.handleUnaryCall<_aria_v1_CreateContainerRequest__Output, _aria_v1_Container>;
  
  GetContainer: grpc.handleUnaryCall<_aria_v1_GetContainerRequest__Output, _aria_v1_Container>;
  
  ListContainers: grpc.handleUnaryCall<_aria_v1_ListContainersRequest__Output, _aria_v1_ListContainersResponse>;
  
  RemoveContainer: grpc.handleUnaryCall<_aria_v1_RemoveContainerRequest__Output, _aria_v1_RemoveContainerResponse>;
  
  StartContainer: grpc.handleUnaryCall<_aria_v1_StartContainerRequest__Output, _aria_v1_StartContainerResponse>;
  
  StopContainer: grpc.handleUnaryCall<_aria_v1_StopContainerRequest__Output, _aria_v1_StopContainerResponse>;
  
  StreamContainerLogs: grpc.handleServerStreamingCall<_aria_v1_StreamContainerLogsRequest__Output, _aria_v1_ContainerLog>;
  
}

export interface ContainerServiceDefinition extends grpc.ServiceDefinition {
  CreateContainer: MethodDefinition<_aria_v1_CreateContainerRequest, _aria_v1_Container, _aria_v1_CreateContainerRequest__Output, _aria_v1_Container__Output>
  GetContainer: MethodDefinition<_aria_v1_GetContainerRequest, _aria_v1_Container, _aria_v1_GetContainerRequest__Output, _aria_v1_Container__Output>
  ListContainers: MethodDefinition<_aria_v1_ListContainersRequest, _aria_v1_ListContainersResponse, _aria_v1_ListContainersRequest__Output, _aria_v1_ListContainersResponse__Output>
  RemoveContainer: MethodDefinition<_aria_v1_RemoveContainerRequest, _aria_v1_RemoveContainerResponse, _aria_v1_RemoveContainerRequest__Output, _aria_v1_RemoveContainerResponse__Output>
  StartContainer: MethodDefinition<_aria_v1_StartContainerRequest, _aria_v1_StartContainerResponse, _aria_v1_StartContainerRequest__Output, _aria_v1_StartContainerResponse__Output>
  StopContainer: MethodDefinition<_aria_v1_StopContainerRequest, _aria_v1_StopContainerResponse, _aria_v1_StopContainerRequest__Output, _aria_v1_StopContainerResponse__Output>
  StreamContainerLogs: MethodDefinition<_aria_v1_StreamContainerLogsRequest, _aria_v1_ContainerLog, _aria_v1_StreamContainerLogsRequest__Output, _aria_v1_ContainerLog__Output>
}
