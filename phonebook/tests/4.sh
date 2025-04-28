#!/bin/bash

echo "Load test"

cd ../server || exit 1

python3 server.py > server.log 2>&1 &
SERVER_PID=$!

cd ../client || exit 1

START_TIME=$(date +%s)

COMMANDS_FILE="load_commands.txt"
echo -n "" > "$COMMANDS_FILE"

for i in {1..50}; do
    echo "add LoadUser$i $i" >> "$COMMANDS_FILE"
done
echo "list" >> "$COMMANDS_FILE"
echo "exit" >> "$COMMANDS_FILE"

python3 client.py < "$COMMANDS_FILE" > load_test_output.txt

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

COUNT=$(grep -c "LoadUser" load_test_output.txt)

if [ "$COUNT" -eq 100 ] && [ "$TOTAL_TIME" -le 5 ]; then
    echo -e "\033[32mTest passed: $COUNT requests for $TOTAL_TIME sec\033[0m"
    RESULT=0
else
    echo -e "\033[31mTest failed: $COUNT/100 requests for $TOTAL_TIME sec\033[0m"
    RESULT=1
fi

rm -f "$COMMANDS_FILE" load_test_output.txt
kill $SERVER_PID
exit $RESULT