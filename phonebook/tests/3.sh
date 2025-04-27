#!/bin/bash

SERVER_FILE="server.py"
CLIENT_FILE="client.py"

# Cleanup on exit
cleanup() {
    if ps -p $SERVER_PID > /dev/null 2>&1; then
        echo "Stopping server (PID $SERVER_PID)..."
        kill $SERVER_PID
    fi
}
trap cleanup EXIT

# Start server
echo "[1/5] Starting server..."
python3 "$SERVER_FILE" &
SERVER_PID=$!
sleep 2

# Check server is alive
if ! ps -p $SERVER_PID > /dev/null; then
    echo "❌ Server failed to start."
    exit 1
fi

# Run both clients
echo "[2/5] add test user..."
python3 "$CLIENT_FILE" --add TestUser 1 &
CLIENT1_PID=$!

sleep 2

echo "[3/5] get test user..."
python3 "$CLIENT_FILE" --get TestUser &
CLIENT2_PID=$!

echo "[4/5] list users..."
python3 "$CLIENT_FILE" --get TestUser &
CLIENT2_PID=$!

# Wait for both clients to complete
wait $CLIENT1_PID
wait $CLIENT2_PID

echo "[5/5] Clients completed. Test successful."