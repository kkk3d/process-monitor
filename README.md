# Process Monitor

Bash-скрипт для мониторинга процесса `test` и отправки heartbeat на удаленный API. Запускается автоматически при загрузке системы через systemd timer.

## Файлы проекта

*   [`test-process-monitor.sh`](./test-process-monitor.sh) - основной скрипт мониторинга
*   [`test-process-monitor.service`](./test-process-monitor.service) - конфигурация systemd сервиса
*   [`test-process-monitor.timer`](./test-process-monitor.timer) - конфигурация systemd таймера

## Быстрая установка

Выполните в терминале на Linux:

```bash
# Скачиваем и размещаем файлы
sudo curl -o /usr/local/bin/test-process-monitor.sh https://raw.githubusercontent.com/kkk3d/process-monitor/main/test-process-monitor.sh
sudo curl -o /etc/systemd/system/test-process-monitor.service https://raw.githubusercontent.com/kkk3d/process-monitor/main/test-process-monitor.service
sudo curl -o /etc/systemd/system/test-process-monitor.timer https://raw.githubusercontent.com/kkk3d/process-monitor/main/test-process-monitor.timer

# Даем права на выполнение скрипту
sudo chmod +x /usr/local/bin/test-process-monitor.sh

# Перезагружаем systemd и включаем автозапуск
sudo systemctl daemon-reload
sudo systemctl enable --now test-process-monitor.timer

# Проверяем статус
sudo systemctl status test-process-monitor.timer
```

## Проверка работы

Просмотр логов:
```bash
journalctl -u test-process-monitor.service -f
```
