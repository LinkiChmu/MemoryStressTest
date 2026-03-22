#!/bin/bash

LOGS_DIR="$HOME/logs"
ALERT_LOG="$LOGS_DIR/critical_alert.log"
METRICS_LOG="$LOGS_DIR/metrics.log"
OOM_LOG="$LOGS_DIR/oom_events.log"

mkdir -p "$LOGS_DIR"

NOW=$(date '+%Y-%m-%d %H:%M:%S')

# --- Сбор метрик состояния ресурсов ОС---
MEM_USAGE=$(free | awk '/^Mem:/ {printf "%.1f", $3/$2 * 100}')

CPU_USAGE=$(top -bn1 | grep '%Cpu(s)' | tail -n1 | awk '{printf "%.1f", 100 - $8}') #  100 - idle

SWAP_TOTAL=$(free | awk '/^Swap:/ {print $2}')
SWAP_USED=$(free | awk '/^Swap:/ {print $3}')
if [[ $SWAP_TOTAL -gt 0 ]]; then
SWAP_USAGE=$(awk "BEGIN {printf \"%.1f\", $SWAP_USED / $SWAP_TOTAL * 100}")
else
SWAP_USAGE="0.0"
fi

# --- Запись метрик ---
echo -e "[$NOW] Memory: ${MEM_USAGE}%\tCPU: ${CPU_USAGE}%\tSwap: ${SWAP_USAGE}%" >> "$METRICS_LOG"


# --- Проверка критических событий ---
CRITICAL=$(journalctl -p err --since "5 minutes ago" --no-pager 2>/dev/null | grep -v '^--')

if [ -n "$CRITICAL" ]; then
echo "[$NOW] Обнаружены критические системные сообщения:" >> "$ALERT_LOG"
echo "$CRITICAL" >> "$ALERT_LOG"
echo "--------------------------------------------------" >> "$ALERT_LOG"
fi

# --- Проверка событий ядра ---
KERNEL_EVENTS=$(sudo dmesg -T | grep -iE 'oom|out of memory|killed process' | tail -10)

if [ -n "$KERNEL_EVENTS" ]; then
echo "[$NOW] Обновлены события ядра (OOM):" >"$OOM_LOG"
echo "$KERNEL_EVENTS" >> "$OOM_LOG"
echo "--------------------------------------------------" >> "$OOM_LOG"
fi