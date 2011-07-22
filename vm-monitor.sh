#!/bin/bash


# configuration
DURATION=$((60 * 60 * 2))
INTERVAL=60

# auto calculated
SCRIPT_NAME=$(basename $0)

DIR_NAME=$(dirname "$0")
START_TIME=$(date +%s)

DATA_FILE="${DIR_NAME}/${SCRIPT_NAME}.data"
PID_FILE="${DIR_NAME}/${SCRIPT_NAME}.pid"
#TEMP_FILE=$(mktemp)
#VMSTAT_PID=0


OutputError() {
    # echo "${SCRIPT_NAME}: error: $1"
    echo "error: $1"
}

OutputUsage() {
    echo "Usage: ${SCRIPT_NAME} {start|stop|status|show}"
}

MonitorLoop () {
    : > "$DATA_FILE"
    echo "$$" > "$PID_FILE"
    while true; do
	vmstat | tail -n 1 > "$DATA_FILE"
    done
}

# API func
start() {
    echo -n "Starting $SCRIPT_NAME ... "
    if [ -e "$PID_FILE" ] && ps -p $(cat "$PID_FILE") &> /dev/null; then
	OutputError 'monitor alreay started'
	exit 1
    fi
    "$0" monitor &
    monitor_pid=$!
    echo "$monitor_pid" > "$PID_FILE"
    echo ok
}

stop() {
    echo -n "Stopping $SCRIPT_NAME ... "
    if [ -e "$PID_FILE" ] && ps -p $(cat "$PID_FILE") &> /dev/null; then
	kill -TERM $(cat "$PID_FILE") &> /dev/null
    else
	OutputError "not started"
	exit 1
    fi
    echo ok
}

status() {
    echo -n "$SCRIPT_NAME "
    if [ -e "$PID_FILE" ] && ps -p $(cat "$PID_FILE") &> /dev/null; then
	echo "(pid $(cat $PID_FILE) ) is running..."
    else
	echo "is stopped"
    fi
}

# never call it directly
monitor() {
    echo "I'm the monitor"
    while [ 1 ]; do
	:
    done
}

case "$1" in
    start)
	start ;;
    stop)
	stop ;;
    status)
	status ;;
    monitor)
	monitor ;;
    *)
	OutputUsage ;;
esac
	
