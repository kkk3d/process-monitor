#!/bin/bash

# Скрипт мониторинга процесса test и отправки heartbeat на API
# Требуется установленный curl

# Имя процесса для мониторинга (можно изменить)
PROCESS_NAME="test"
# URL для отправки heartbeat
HEARTBEAT_URL="https://test.com/monitoring/test/api"
# Файл для отслеживания предыдущего состояния процесса
STATE_FILE="/var/run/test-process-monitor.state"
# Файл лога
LOG_FILE="/var/log/monitoring.log"

# Функция для логирования в файл и journald
log_message() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" | tee -a "$LOG_FILE" | systemd-cat -t test-process-monitor
}

# Функция для проверки доступности сервера мониторинга
check_server_availability() {
    if ! curl -s -I --connect-timeout 5 "$HEARTBEAT_URL" > /dev/null 2>&1; then
        log_message "ERROR: Сервер мониторинга $HEARTBEAT_URL недоступен"
        return 1
    fi
    return 0
}

# Функция для определения, был ли процесс перезапущен
check_process_restart() {
    local current_state="$1"
    local previous_state=""
    
    # Читаем предыдущее состояние из файла
    if [[ -f "$STATE_FILE" ]]; then
        previous_state=$(cat "$STATE_FILE")
    fi
    
    # Сохраняем текущее состояние
    echo "$current_state" > "$STATE_FILE"
    
    # Если предыдущее состояние было "running" а сейчас "not running" - был остановлен
    # Если предыдущее состояние было "not running" а сейчас "running" - был запущен/перезапущен
    if [[ "$previous_state" == "not running" && "$current_state" == "running" ]]; then
        log_message "INFO: Процесс $PROCESS_NAME был запущен/перезапущен"
        return 0
    fi
    
    return 1
}

# Проверяем, установлен ли curl
if ! command -v curl &> /dev/null; then
    log_message "ERROR: curl не установлен. Выход."
    exit 1
fi

# Проверяем доступность сервера мониторинга
if ! check_server_availability; then
    exit 1
fi

# Проверяем, запущен ли процесс
if pgrep -x "$PROCESS_NAME" > /dev/null; then
    current_state="running"
    
    # Проверяем, был ли процесс перезапущен
    if check_process_restart "$current_state"; then
        # Логирование перезапуска уже выполнено в функции check_process_restart
        :
    fi
    
    # Процесс запущен, отправляем heartbeat
    log_message "INFO: Процесс $PROCESS_NAME запущен. Отправляю heartbeat на $HEARTBEAT_URL"
    
    # Отправляем HTTP GET запрос
    response=$(curl -s -o /dev/null -w "%{http_code}" \
               -H "Content-Type: application/json" \
               -X GET "$HEARTBEAT_URL" \
               --connect-timeout 10 \
               --max-time 15 2>> /dev/null)
    
    # Проверяем код ответа
    if [[ "$response" -eq 200 ]] || [[ "$response" -eq 201 ]] || [[ "$response" -eq 202 ]]; then
        log_message "INFO: Heartbeat успешно отправлен. HTTP код: $response"
    else
        log_message "WARNING: Не удалось отправить heartbeat. HTTP код: $response"
        # Дополнительная проверка: если curl завершился с ошибкой
        if [[ $? -ne 0 ]]; then
            log_message "ERROR: Ошибка выполнения curl при отправке heartbeat"
        fi
    fi
else
    current_state="not running"
    # Сохраняем состояние "не запущен"
    check_process_restart "$current_state" > /dev/null 2>&1
    # Логируем только факт отсутствия процесса, но не отправляем heartbeat
    log_message "INFO: Процесс $PROCESS_NAME не запущен. Heartbeat не отправляется."
fi

exit 0
