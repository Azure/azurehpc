#!/bin/bash

PROLOG_RUN_NHC=$2

while [ ! -f /usr/sbin/nhc ];do
sleep 2
echo "[Prolog] waiting for aznhc" >> /var/log/nhc.log
done

# Is AzNHC running?
# - Returns 1 if running, returns 0 if not running.
function is_aznhc_running() {
    sudo docker ps --format '{{.Names}}' | grep -v -q "^aznhc$"
}

is_aznhc_running
aznhc_rc=$?
if [ aznhc_rc -eq 1 ]; then
   while is_aznhc_running > /dev/null 2>&1
   do
        sleep 10
        TIMESTAMP=$(/bin/date '+%Y%m%d %H:%M:%S')
        echo "${TIMESTAMP} [prolog] NHC processes still running" >> /var/log/nhc.log
   done

   TIMESTAMP=$(/bin/date '+%Y%m%d %H:%M:%S')
   echo "${TIMESTAMP} [prolog] NHC processes finished and job can start" >> /var/log/nhc.log
elif [[ $PROLOG_RUN_NHC == 1 ]]; then
   /sched/scripts/run_nhc.sh
fi

