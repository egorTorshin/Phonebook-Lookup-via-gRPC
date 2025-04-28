#!/bin/bash
# tests/interactive_session_test.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Interactive gRPC Test Session ===${NC}"

# Start server
echo -e "\n${YELLOW}[1/3] Starting server...${NC}"
cd ../server || exit
python3 server.py &
SERVER_PID=$!
sleep 3
echo -e "  Server PID: $SERVER_PID"

# Create named pipe for communication
FIFO_FILE="/tmp/grpc_test_fifo"
mkfifo "$FIFO_FILE"

# Start client in background
echo -e "\n${YELLOW}[2/3] Starting client session...${NC}"
cd ../client || exit
python3 client.py > "$FIFO_FILE" &
CLIENT_PID=$!

# Function to send commands
send_command() {
    echo "$1" > "$FIFO_FILE"
    sleep 0.5 # Small delay for processing
}

# Read output with colors
while read -r line; do
    if [[ "$line" == *"> "* ]]; then
        # Command prompts in yellow
        echo -e "${YELLOW}$line${NC}"
    elif [[ "$line" == *"added"* || "$line" == *"found"* || "$line" == *"success"* ]]; then
        # Success messages in green
        echo -e "${GREEN}$line${NC}"
    elif [[ "$line" == *"not found"* || "$line" == *"error"* ]]; then
        # Error messages in red
        echo -e "${RED}$line${NC}"
    else
        # Regular output
        echo "$line"
    fi
done < "$FIFO_FILE" &

# Send test commands
send_command "add TestUser 1234567890"
send_command "get TestUser"
send_command "list"
send_command "delete TestUser"
send_command "list"
send_command "exit"

# Cleanup
echo -e "\n${YELLOW}[3/3] Cleaning up...${NC}"
wait $CLIENT_PID
rm "$FIFO_FILE"
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null
echo -e "${GREEN}Test completed!${NC}"