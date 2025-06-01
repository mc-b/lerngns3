#!/bin/bash

# Einfaches Monitoring-Skript für CPU, RAM, SWAP, SSD
INTERVAL=10

echo "Monitoring gestartet... (Abbruch mit STRG+C)"
echo -e "Zeit\t\tCPU(%)\tRAM(%)\tSWAP(%)\tSSD(%)"

while true; do
    # Zeit
    TIME=$(date +"%H:%M:%S")

    # CPU-Idle aus /proc/stat -> CPU-Last in %
    CPU_IDLE=$(awk '/^cpu / {idle=$5; total=$2+$3+$4+$5+$6+$7+$8; print idle, total}' /proc/stat)
    IDLE_PREV=$(echo $CPU_IDLE | awk '{print $1}')
    TOTAL_PREV=$(echo $CPU_IDLE | awk '{print $2}')
    sleep 1
    CPU_IDLE2=$(awk '/^cpu / {idle=$5; total=$2+$3+$4+$5+$6+$7+$8; print idle, total}' /proc/stat)
    IDLE_CUR=$(echo $CPU_IDLE2 | awk '{print $1}')
    TOTAL_CUR=$(echo $CPU_IDLE2 | awk '{print $2}')
    DIFF_IDLE=$((IDLE_CUR - IDLE_PREV))
    DIFF_TOTAL=$((TOTAL_CUR - TOTAL_PREV))
    CPU_USAGE=$((100 - (100 * DIFF_IDLE / DIFF_TOTAL)))

    # RAM-Auslastung in %
    MEM_INFO=$(free | awk '/Mem:/ {print $3/$2 * 100.0}')
    RAM_USAGE=$(printf "%.0f" $MEM_INFO)

    # Swap-Nutzung in %
    SWAP_INFO=$(free | awk '/Swap:/ {if ($2 > 0) print $3/$2 * 100.0; else print 0}')
    SWAP_USAGE=$(printf "%.0f" $SWAP_INFO)

    # SSD-Auslastung (nur für sda)
    SSD_UTIL=$(iostat -dx sda 1 1 | awk '/sda/ {print $NF}' | tail -1)
    SSD_USAGE=$(printf "%.0f" $SSD_UTIL)

    echo -e "$TIME\t$CPU_USAGE\t$RAM_USAGE\t$SWAP_USAGE\t$SSD_USAGE"

    sleep $INTERVAL
done
