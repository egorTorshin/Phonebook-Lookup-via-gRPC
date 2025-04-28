#!/bin/bash
# tests/integration_test.sh

cd server
SERVER_FILE="server.py"
CLIENT_FILE="../client/client.py"

cleanup() {
    if ps -p $SERVER_PID > /dev/null; then
        echo "Stopping server (PID $SERVER_PID)..."
        kill $SERVER_PID
    fi
    rm -f test_commands.txt
}
trap cleanup EXIT

# 1. Start server
echo "[1/5] Starting server..."
python3 "$SERVER_FILE" &
SERVER_PID=$!
sleep 5  # Wait for gRPC server to initialize

# 2. Prepare test commands
echo "[2/5] Preparing test commands..."
cat > test_commands.txt <<EOF
add TestUser 1234567890
get TestUser
list
delete TestUser
exit
EOF

# 3. Run client with all commands
echo "[3/5] Running test sequence..."
python3 "$CLIENT_FILE" < test_commands.txt > test_output.txt 2>&1

# 4. Verify results
echo "[4/5] Verifying results..."
if grep -q "Contact TestUser added" test_output.txt && \
   grep -q "TestUser: 1234567890" test_output.txt && \
   grep -q "Contact TestUser deleted" test_output.txt; then
    echo "[5/5] All