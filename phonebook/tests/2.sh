#!/bin/bash
# tests/test_add_get_contact.sh
echo "=== Тест добавления и получения контакта ==="

cd ../server
python3 server.py &
SERVER_PID=$!
sleep 2

cd ../client
python3 client.py &
ADD_RESULT=$(add TestUser 1234567890)
GET_RESULT=$(get TestUser 1234567890)

if [[ $ADD_RESULT && $GET_RESULT ]]; then
    echo -e "\033[32mТест пройден\033[0m"
    kill $SERVER_PID
    exit 0
else
    echo -e "\033[31mТест не пройден\033[0m"
    kill $SERVER_PID
    exit 1
fi