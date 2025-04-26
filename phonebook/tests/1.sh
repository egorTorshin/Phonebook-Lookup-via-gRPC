#!/bin/bash

PROTO_FILE="gRPC.proto"
SERVER_FILE="server.py"

echo "[1/3] Compiling $PROTO_FILE..."
python3 -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. "$PROTO_FILE" || {
    echo "❌ Failed to compile proto file."
    exit 1
}

echo "[2/3] Starting server in background..."
python3 "$SERVER_FILE" &
SERVER_PID=$!
sleep 2

echo "[3/3] Checking if server is running..."
if ps -p $SERVER_PID > /dev/null; then
    echo "✅ Server is running (PID: $SERVER_PID)"
    kill $SERVER_PID
    exit 0
else
    echo "❌ Server failed to start or crashed."
    exit 1
fi
