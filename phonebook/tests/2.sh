#!/bin/bash
cd ../server
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
echo "[1/3] Starting server..."
python3 "$SERVER_FILE" &
SERVER_PID=$!
sleep 2

# Check server is alive
if ! ps -p $SERVER_PID > /dev/null; then
    echo "❌ Server failed to start."
    exit 1
fi
cd ../client
# Run both clients
echo "[2/3] Running client..."
python3 "$CLIENT_FILE" &
CLIENT_PID=$!

sleep 2

# Wait for both clients to complete
wait $CLIENT_PID

echo "[3/3] Clients completed. Test successful."
