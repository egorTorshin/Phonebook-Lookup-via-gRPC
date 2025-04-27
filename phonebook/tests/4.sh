#!/bin/bash
# tests/test_load.sh

echo "=== Нагрузочный тест (100 RPS) ==="

# Переходим в директорию сервера
cd ../server || exit 1

# Запускаем сервер
python3 server.py > server.log 2>&1 &
SERVER_PID=$!
sleep 5  # Увеличили время ожидания для gRPC

# Переходим в директорию клиента
cd ../client || exit 1

START_TIME=$(date +%s)

# Генерируем файл с командами
COMMANDS_FILE="load_commands.txt"
echo -n "" > "$COMMANDS_FILE"

for i in {1..50}; do
    echo "add LoadUser$i $i" >> "$COMMANDS_FILE"
done
echo "list" >> "$COMMANDS_FILE"
echo "exit" >> "$COMMANDS_FILE"

# Запускаем клиент с пакетной обработкой команд
python3 client.py < "$COMMANDS_FILE" > load_test_output.txt

# Измеряем время выполнения
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

# Проверяем результаты
COUNT=$(grep -c "LoadUser" load_test_output.txt)

if [ "$COUNT" -eq 100 ] && [ "$TOTAL_TIME" -le 5 ]; then
    echo -e "\033[32mТест пройден: $COUNT запросов за $TOTAL_TIME сек\033[0m"
    RESULT=0
else
    echo -e "\033[31mТест не пройден: $COUNT/100 запросов за $TOTAL_TIME сек\033[0m"
    RESULT=1
fi

# Очистка
rm -f "$COMMANDS_FILE" load_test_output.txt
kill $SERVER_PID
exit $RESULT