#!/bin/bash


# configuration
DURATION=$((60 * 60 * 2))
INTERVAL=3 			# 60
DATE_FORMAT='%Y-%m-%d %H-%M-%S'
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

AnalysisData() {
    awk 'function abs(n){if(n<0) n=-n; return n;}
function hilight(val,avg){
   if (abs(val-avg)> avg*0.1) return sprintf("\033[31;1m%.0f\033[0m",val);
   else return sprintf("%.0f",val);
}
{
  if( $1!="#" ){
    i=1;
    num+=1;
    while(i<=NF){
      data[i,"sum"]+=$i;
      if ($i>data[i,"max"]) data[i,"max"]=$i;
      if (data[i,"min"]==0) data[i,"min"]=$i;
      else if ($i<data[i,"min"]) data[i,"min"]=$i;
      i+=1;
    }
  }
  else print $0;
}  
END{
  split("r b swpd free buff cache si so bi bo in cs us sy id wa",header,/ /);
  i=1;
  print "\033[;4;1mItem\tAverage\tMaximum\tMinimum\033[0m"
  while(i<=16){
    avg=data[i,"sum"]/num;
    printf "\033[;1m%s\033[0m\t%.0f\t%s\t%s\n", header[i], \
      avg, hilight(data[i,"max"],avg), hilight(data[i,"min"],avg);
    i+=1;
  }
  print "Calculated", num, "items"
}' "$DATA_FILE"
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
	date "+# To $DATE_FORMAT" >> "$DATA_FILE"
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

show() {
    # calculates
    echo -n "Analysising result ... "
    if [ ! -e "$DATA_FILE" ]; then
	OutputError "no data to analysis"
	exit 1
    elif [ $(wc -l "$DATA_FILE" | cut -d' ' -f1) -lt 10 ]; then
	OutputError "too few data to analysis"
	exit 1
    else
	echo "ok"
	AnalysisData
    fi
}

# never call it directly
monitor() {
    echo "Monitor Started at $(date)"
    # : > "$DATA_FILE"
    echo "$$" > "$PID_FILE"
    date "+# From $DATE_FORMAT" > "$DATA_FILE"
    while true; do
	vmstat | tail -n 1 >> "$DATA_FILE"
	sleep $INTERVAL
    done
}



case "$1" in
    start)
	start ;;
    stop)
	stop ;;
    status)
	status ;;
    show)
	show ;;
    monitor)
	monitor ;;
    *)
	OutputUsage ;;
esac
	
