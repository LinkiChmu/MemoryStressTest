## Среда для тестирования поведения ОС при нехватке памяти

Работа проводится в виртуальной машине Oracle VirtualBox

### 1. Имитируется процесс с утечкой памяти

Установить пакет `numpy`для имитации создания датасета
```shell
sudo apt install python3-numpy
```

Сделать файл, вызывающий переполнение памяти и выброс ошибки Out Of Memory, исполняемым
```shell
chmod +x ./scripts/memory_leak.py
```
Запустить исполнение файла
```shell
python3 ./scripts/memory_leak.py
```

### 2. Система автоматически (раз в пять минут) отслеживает состояние ресурсов ОС и критические события

Для просмотра журанала системных событий ОС требуется добавить пользователя в группу systemd-journal:

```shell
sudo usermod -aG systemd-journal $USER
newgrp systemd-journal
```
Отредактировать `Crontab` (добавить запись в конец файла) для работы по расписанию (каждые 5 минут)
```shell
sudo nano /etc/crontab
*/5 * * * * vboxuser /home/vboxuser/scripts/check_resources.sh >> /home/vboxuser/logs/cron.log 2>&1
```
В скрипте `./scripts/check_resources.sh` описан сбор метрик (Memory/Swap/CPU) и дозапись их в лог `logs/metrics.log`.
Также производится проверка критических событий за последние 5 минут и дозапись в лог `logs/critical_alert.log`

### 4. Анализируются события ядра (включая работу OOM-killer)

Поскольку утилита `dmesg` показывает всю историю буфера ядра, для избежания дублирования событий лог `logs/oom_events.log` перезаписывается последними 10 событиями ядра

