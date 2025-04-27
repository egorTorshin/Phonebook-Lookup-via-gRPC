#!/bin/bash
SERVER_FILE="../server/server.py"
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

# Тестирование
echo "[2/5] Adding test user..."
python3 "$CLIENT_FILE" "add TestUser" 1234567890 || {
    echo "Ошибка добавления контакта"
    exit 1
}


sleep 1

echo "[3/5] Getting test user..."
python3 "$CLIENT_FILE" "get TestUser" || {
    echo "Failed to get contact"
    exit 1
}

sleep 1

echo "[4/5] Listing users..."
echo -e "list" | python3 "$CLIENT_FILE" || {
    echo "Failed to list contacts"
    exit 1
}

sleep 1

echo "[5/5] Test completed successfully"
