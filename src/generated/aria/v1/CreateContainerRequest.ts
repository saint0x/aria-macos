// Original file: src/proto/container_service.proto

import type { KeyValuePair as _aria_v1_KeyValuePair, KeyValuePair__Output as _aria_v1_KeyValuePair__Output } from '../../aria/v1/KeyValuePair';

export interface CreateContainerRequest {
  'name'?: (string);
  'imagePath'?: (string);
  'environment'?: (_aria_v1_KeyValuePair)[];
  'persistent'?: (boolean);
}

export interface CreateContainerRequest__Output {
  'name': (string);
  'imagePath': (string);
  'environment': (_aria_v1_KeyValuePair__Output)[];
  'persistent': (boolean);
}
