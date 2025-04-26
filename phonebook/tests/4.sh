#!/bin/bash
# tests/test_load.sh
echo "=== Нагрузочный тест (100 RPS) ==="

cd ../server
python3 server.py &
SERVER_PID=$!
sleep 2

cd ../../client
START_TIME=$(date +%s)

# 100 запросов с паузой 0.01 сек между ними (~100 RPS)
for i in {1..100}; do
    python3 client.py add "LoadUser$i" "$i" > /dev/null &
    sleep 0.01
done
wait

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME-START_TIME))

COUNT=$(python3 client.py list | grep -c "LoadUser")

if [ $TOTAL_TIME -le 2 ] && [ $COUNT -eq 100 ]; then
    echo -e "\033[32mНагрузочный тест пройден ($COUNT запросов за $TOTAL_TIME сек)\033[0m"
else
    echo -e "\033[31mНагрузочный тест не пройден ($COUNT/100 за $TOTAL_TIME сек)\033[0m"
fi

kill $SERVER_PID