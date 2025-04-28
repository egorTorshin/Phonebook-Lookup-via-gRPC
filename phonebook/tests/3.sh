#!/bin/bash
# tests/interactive_test.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Header
echo -e "${YELLOW}=== Interactive gRPC Client Test ===${NC}"

# Start server
echo -e "\n${YELLOW}[1/3] Starting server...${NC}"
cd server || exit
python3 server.py &
SERVER_PID=$!
sleep 3
echo -e "  Server PID: $SERVER_PID"

# Test function
run_command() {
    echo -e "\n${YELLOW}>>> $1${NC}"
    echo "$1" | python3 ../client/client.py | while read -r line; do
        if [[ "$line" == *"error"* || "$line" == *"fail"* ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ "$line" == *"success"* || "$line" == *"added"* || "$line" == *"found"* ]]; then
            echo -e "${GREEN}$line${NC}"
        else
            echo "$line"
        fi
    done
}

# Test sequence
echo -e "\n${YELLOW}[2/3] Running test sequence...${NC}"
cd ../client || exit

run_command "add TestUser 1234567890"
run_command "get TestUser"
run_command "list"
run_command "delete TestUser"
run_command "list"

# Cleanup
echo -e "\n${YELLOW}[3/3] Cleaning up...${NC}"
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null
echo -e "${GREEN}Test completed successfully!${NC}"