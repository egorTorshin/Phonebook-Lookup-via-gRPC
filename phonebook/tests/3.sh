#!/bin/bash
cd ../server
SERVER_FILE="server.py"
CLIENT_FILE="../client/client.py"

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
sleep 5  # Увеличил время ожидания для gRPC сервера

cd ../client
# Тестирование
echo "[2/5] Adding test user..."
python3 "$CLIENT_FILE" &
--command "add TestUser 1"
if [ $? -ne 0 ]; then
    echo "Failed to add contact"
    exit 1
fi

sleep 1

echo "[3/5] Getting test user..."
python3 "$CLIENT_FILE" --command "get TestUser"
if [ $? -ne 0 ]; then
    echo "Failed to get contact"
    exit 1
fi

sleep 1

echo "[4/5] Listing users..."
python3 "$CLIENT_FILE:" 
--command "list"
if [ $? -ne 0 ]; then
    echo "Failed to list contacts"
    exit 1
fi

sleep 1

echo "[5/5] Test completed successfully"