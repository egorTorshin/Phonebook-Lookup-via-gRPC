#!/bin/bash
# tests/integration_test.sh

# Переходим в корень проекта
cd "$(dirname "$0")/.." || exit 1

SERVER_DIR="server"
CLIENT_DIR="client"
TEST_COMMANDS="$SERVER_DIR/test_commands.txt"
TEST_OUTPUT="$SERVER_DIR/test_output.txt"

cleanup() {
    if ps -p $SERVER_PID > /dev/null; then
        echo "Stopping server (PID $SERVER_PID)..."
        kill $SERVER_PID
    fi
    rm -f "$TEST_COMMANDS" "$TEST_OUTPUT"
}
trap cleanup EXIT

# 1. Запуск сервера
echo "[1/4] Starting server..."
cd "$SERVER_DIR" || exit 1
python3 server.py &
SERVER_PID=$!
sleep 5  # Ожидание инициализации gRPC

# 2. Подготовка команд
echo "[2/4] Preparing test commands..."
cat > "$TEST_COMMANDS" <<EOF
add TestUser 1234567890
get TestUser
list
delete TestUser
exit
EOF

# 3. Выполнение тестов
echo "[3/4] Running tests..."
cd "../$CLIENT_DIR" || exit 1
python3 client.py < "../$TEST_COMMANDS" > "../$TEST_OUTPUT" 2>&1

# 4. Проверка результатов
echo "[4/4] Verifying results..."
cd "../$SERVER_DIR" || exit 1
if grep -q "Contact TestUser added" "$TEST_OUTPUT" && \
   grep -q "TestUser: 1234567890" "$TEST_OUTPUT" && \
   grep -q "Contact TestUser deleted" "$TEST_OUTPUT"; then
    echo "All tests passed successfully!"
    exit 0
else
    echo "Test failed. Output:"
    cat "$TEST_OUTPUT"
    exit 1
fi