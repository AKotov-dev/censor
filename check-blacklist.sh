#!/bin/bash

# The script removes dead URLs from the blacklist_filename
# The script requires the netcat (nc) package
# Usage: ./check-blacklist.sh blacklist_filename

clear

INPUT_FILE="$1"
TEMP_FILE="$(mktemp)"
LOG_FILE="check.log"
MAX_JOBS=20  # Кол-во одновременных проверок
PING_TARGET="8.8.8.8"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Файл $INPUT_FILE не найден."
    exit 1
fi

echo "Проверка интернет-соединения..."
if ! ping -c 2 -W 2 "$PING_TARGET" &>/dev/null; then
    echo "Нет подключения к интернету или пинг до $PING_TARGET не проходит. Скрипт остановлен."
    exit 1
fi
# echo "Интернет доступен. Продолжаем."

> "$LOG_FILE"
> "$TEMP_FILE"

check_site() {
    local site="$1"
#    echo "Проверяем $site..."
    for attempt in 1 2; do
        for port in 80 443; do
            if nc -z -w3 "$site" "$port" 2>/dev/null; then
                if [[ $attempt -eq 1 ]]; then
                    echo "$site — доступен" | tee -a "$LOG_FILE"
                else
                    echo "$site — доступен (со второй попытки)" | tee -a "$LOG_FILE"
                fi
                echo "$site" >> "$TEMP_FILE"
                return 0
            fi
        done
        if [[ $attempt -eq 1 ]]; then
            sleep 2
            echo "Повторная проверка $site..."
        fi
    done
    echo "$site — недоступен, удаляем из списка" | tee -a "$LOG_FILE"
    return 1
}

export -f check_site
export TEMP_FILE LOG_FILE

grep -v '^\s*$' "$INPUT_FILE" | grep -v '^#' | xargs -P "$MAX_JOBS" -I {} bash -c 'check_site "$@"' _ {}

sort "$TEMP_FILE" -o "$TEMP_FILE"
mv -i "$TEMP_FILE" "$INPUT_FILE"

echo -e "---\nПроверка завершена. Лог в $LOG_FILE."
