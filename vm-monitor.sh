#!/bin/bash


# configuration
DURATION=$((60 * 60 * 2))
INTERVAL=60

# auto calculated
SCRIPT_NAME=$(basename $0)

DIR_NAME=$(dirname "$0")
START_TIME=$(date +%s)

#TEMP_FILE=$(mktemp)
VMSTAT_PID=0


vmstat 5 | tail -n 1 > $TEMP_FILE
VMSTAT_PID=
