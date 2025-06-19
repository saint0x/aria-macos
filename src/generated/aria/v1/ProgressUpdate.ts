// Original file: src/proto/task_service.proto


export interface ProgressUpdate {
  'percentComplete'?: (number | string);
  'operationDescription'?: (string);
}

export interface ProgressUpdate__Output {
  'percentComplete': (number);
  'operationDescription': (string);
}
