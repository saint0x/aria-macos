#!/bin/bash

# This script generates Swift code from the proto files
# It requires protoc and the Swift protobuf plugins to be installed

PROTO_DIR="$(dirname "$0")"
OUTPUT_DIR="$PROTO_DIR/../Generated"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Generate Swift code for each proto file
protoc \
    --proto_path="$PROTO_DIR" \
    --swift_out="$OUTPUT_DIR" \
    --grpc-swift_out="$OUTPUT_DIR" \
    --swift_opt=Visibility=Public \
    --grpc-swift_opt=Visibility=Public \
    "$PROTO_DIR"/*.proto

echo "Swift code generated in $OUTPUT_DIR"