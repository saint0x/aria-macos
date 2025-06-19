// Original file: src/proto/notification_service.proto


export interface BundleUploadEvent {
  'bundleName'?: (string);
  'progressPercent'?: (number | string);
  'statusMessage'?: (string);
  'success'?: (boolean);
  'errorMessage'?: (string);
  '_errorMessage'?: "errorMessage";
}

export interface BundleUploadEvent__Output {
  'bundleName': (string);
  'progressPercent': (number);
  'statusMessage': (string);
  'success': (boolean);
  'errorMessage'?: (string);
  '_errorMessage'?: "errorMessage";
}
