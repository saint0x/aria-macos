// Original file: src/proto/task_service.proto

import type * as grpc from '@grpc/grpc-js'
import type { MethodDefinition } from '@grpc/proto-loader'
import type { CancelTaskRequest as _aria_v1_CancelTaskRequest, CancelTaskRequest__Output as _aria_v1_CancelTaskRequest__Output } from '../../aria/v1/CancelTaskRequest';
import type { CancelTaskResponse as _aria_v1_CancelTaskResponse, CancelTaskResponse__Output as _aria_v1_CancelTaskResponse__Output } from '../../aria/v1/CancelTaskResponse';
import type { GetTaskRequest as _aria_v1_GetTaskRequest, GetTaskRequest__Output as _aria_v1_GetTaskRequest__Output } from '../../aria/v1/GetTaskRequest';
import type { LaunchTaskRequest as _aria_v1_LaunchTaskRequest, LaunchTaskRequest__Output as _aria_v1_LaunchTaskRequest__Output } from '../../aria/v1/LaunchTaskRequest';
import type { LaunchTaskResponse as _aria_v1_LaunchTaskResponse, LaunchTaskResponse__Output as _aria_v1_LaunchTaskResponse__Output } from '../../aria/v1/LaunchTaskResponse';
import type { StreamTaskOutputRequest as _aria_v1_StreamTaskOutputRequest, StreamTaskOutputRequest__Output as _aria_v1_StreamTaskOutputRequest__Output } from '../../aria/v1/StreamTaskOutputRequest';
import type { Task as _aria_v1_Task, Task__Output as _aria_v1_Task__Output } from '../../aria/v1/Task';
import type { TaskOutput as _aria_v1_TaskOutput, TaskOutput__Output as _aria_v1_TaskOutput__Output } from '../../aria/v1/TaskOutput';

export interface TaskServiceClient extends grpc.Client {
  CancelTask(argument: _aria_v1_CancelTaskRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_CancelTaskResponse__Output>): grpc.ClientUnaryCall;
  CancelTask(argument: _aria_v1_CancelTaskRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_CancelTaskResponse__Output>): grpc.ClientUnaryCall;
  CancelTask(argument: _aria_v1_CancelTaskRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_CancelTaskResponse__Output>): grpc.ClientUnaryCall;
  CancelTask(argument: _aria_v1_CancelTaskRequest, callback: grpc.requestCallback<_aria_v1_CancelTaskResponse__Output>): grpc.ClientUnaryCall;
  cancelTask(argument: _aria_v1_CancelTaskRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_CancelTaskResponse__Output>): grpc.ClientUnaryCall;
  cancelTask(argument: _aria_v1_CancelTaskRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_CancelTaskResponse__Output>): grpc.ClientUnaryCall;
  cancelTask(argument: _aria_v1_CancelTaskRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_CancelTaskResponse__Output>): grpc.ClientUnaryCall;
  cancelTask(argument: _aria_v1_CancelTaskRequest, callback: grpc.requestCallback<_aria_v1_CancelTaskResponse__Output>): grpc.ClientUnaryCall;
  
  GetTask(argument: _aria_v1_GetTaskRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Task__Output>): grpc.ClientUnaryCall;
  GetTask(argument: _aria_v1_GetTaskRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_Task__Output>): grpc.ClientUnaryCall;
  GetTask(argument: _aria_v1_GetTaskRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Task__Output>): grpc.ClientUnaryCall;
  GetTask(argument: _aria_v1_GetTaskRequest, callback: grpc.requestCallback<_aria_v1_Task__Output>): grpc.ClientUnaryCall;
  getTask(argument: _aria_v1_GetTaskRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Task__Output>): grpc.ClientUnaryCall;
  getTask(argument: _aria_v1_GetTaskRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_Task__Output>): grpc.ClientUnaryCall;
  getTask(argument: _aria_v1_GetTaskRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_Task__Output>): grpc.ClientUnaryCall;
  getTask(argument: _aria_v1_GetTaskRequest, callback: grpc.requestCallback<_aria_v1_Task__Output>): grpc.ClientUnaryCall;
  
  LaunchTask(argument: _aria_v1_LaunchTaskRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_LaunchTaskResponse__Output>): grpc.ClientUnaryCall;
  LaunchTask(argument: _aria_v1_LaunchTaskRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_LaunchTaskResponse__Output>): grpc.ClientUnaryCall;
  LaunchTask(argument: _aria_v1_LaunchTaskRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_LaunchTaskResponse__Output>): grpc.ClientUnaryCall;
  LaunchTask(argument: _aria_v1_LaunchTaskRequest, callback: grpc.requestCallback<_aria_v1_LaunchTaskResponse__Output>): grpc.ClientUnaryCall;
  launchTask(argument: _aria_v1_LaunchTaskRequest, metadata: grpc.Metadata, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_LaunchTaskResponse__Output>): grpc.ClientUnaryCall;
  launchTask(argument: _aria_v1_LaunchTaskRequest, metadata: grpc.Metadata, callback: grpc.requestCallback<_aria_v1_LaunchTaskResponse__Output>): grpc.ClientUnaryCall;
  launchTask(argument: _aria_v1_LaunchTaskRequest, options: grpc.CallOptions, callback: grpc.requestCallback<_aria_v1_LaunchTaskResponse__Output>): grpc.ClientUnaryCall;
  launchTask(argument: _aria_v1_LaunchTaskRequest, callback: grpc.requestCallback<_aria_v1_LaunchTaskResponse__Output>): grpc.ClientUnaryCall;
  
  StreamTaskOutput(argument: _aria_v1_StreamTaskOutputRequest, metadata: grpc.Metadata, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_TaskOutput__Output>;
  StreamTaskOutput(argument: _aria_v1_StreamTaskOutputRequest, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_TaskOutput__Output>;
  streamTaskOutput(argument: _aria_v1_StreamTaskOutputRequest, metadata: grpc.Metadata, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_TaskOutput__Output>;
  streamTaskOutput(argument: _aria_v1_StreamTaskOutputRequest, options?: grpc.CallOptions): grpc.ClientReadableStream<_aria_v1_TaskOutput__Output>;
  
}

export interface TaskServiceHandlers extends grpc.UntypedServiceImplementation {
  CancelTask: grpc.handleUnaryCall<_aria_v1_CancelTaskRequest__Output, _aria_v1_CancelTaskResponse>;
  
  GetTask: grpc.handleUnaryCall<_aria_v1_GetTaskRequest__Output, _aria_v1_Task>;
  
  LaunchTask: grpc.handleUnaryCall<_aria_v1_LaunchTaskRequest__Output, _aria_v1_LaunchTaskResponse>;
  
  StreamTaskOutput: grpc.handleServerStreamingCall<_aria_v1_StreamTaskOutputRequest__Output, _aria_v1_TaskOutput>;
  
}

export interface TaskServiceDefinition extends grpc.ServiceDefinition {
  CancelTask: MethodDefinition<_aria_v1_CancelTaskRequest, _aria_v1_CancelTaskResponse, _aria_v1_CancelTaskRequest__Output, _aria_v1_CancelTaskResponse__Output>
  GetTask: MethodDefinition<_aria_v1_GetTaskRequest, _aria_v1_Task, _aria_v1_GetTaskRequest__Output, _aria_v1_Task__Output>
  LaunchTask: MethodDefinition<_aria_v1_LaunchTaskRequest, _aria_v1_LaunchTaskResponse, _aria_v1_LaunchTaskRequest__Output, _aria_v1_LaunchTaskResponse__Output>
  StreamTaskOutput: MethodDefinition<_aria_v1_StreamTaskOutputRequest, _aria_v1_TaskOutput, _aria_v1_StreamTaskOutputRequest__Output, _aria_v1_TaskOutput__Output>
}
