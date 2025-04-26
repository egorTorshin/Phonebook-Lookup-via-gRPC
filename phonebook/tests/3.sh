#!/bin/bash
# tests/test_concurrency.sh
echo "=== Тест конкурентного доступа ==="

cd ../server
python3 server.py &
SERVER_PID=$!
sleep 2

cd ../../client

# Функция для добавления контактов
add_contacts() {
    for i in {1..50}; do
        python3 client.py add "User$i" "$i" > /dev/null
    done
}

# Запуск в 2 параллельных процесса
add_contacts &
add_contacts &
wait

COUNT=$(python3 client.py list | grep -c "User")

if [ $COUNT -eq 100 ]; then
    echo -e "\033[32mКонкурентный тест пройден (100 контактов)\033[0m"
else
    echo -e "\033[31mКонкурентный тест не пройден (найдено $COUNT/100)\033[0m"
fi

kill $SERVER_PID