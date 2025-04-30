#!/bin/bash
echo "=== Тест запуска сервера ==="

cd ../server
python3 server.py &
SERVER_PID=$!
sleep 2

if ps -p $SERVER_PID > /dev/null; then
    echo -e "\033[32mServer started succesfully\033[0m"
    kill $SERVER_PID
    exit 0
else
    echo -e "\033[31mError\033[0m"
    exit 1
fi