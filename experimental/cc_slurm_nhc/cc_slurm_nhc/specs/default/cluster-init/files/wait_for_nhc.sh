#!/bin/bash

$2 = PROLOG_RUN_NHC

while [ ! -f /usr/sbin/nhc ];do
sleep 2
echo "[Prolog] waiting for /usr/sbin/nhc" >> /var/log/nhc.log
done

pid=`ps -ef | grep -v grep | grep /usr/sbin/nhc | tr -s ' ' | cut -d ' ' -f2 | head -n 1`

if [ -n "$pid" ]; then
   while ps -p $pid > /dev/null 2>&1
   do
        sleep 10
        TIMESTAMP=$(/bin/date '+%Y%m%d %H:%M:%S')
        echo "${TIMESTAMP} [prolog] NHC processes still running" >> /var/log/nhc.log
   done

   TIMESTAMP=$(/bin/date '+%Y%m%d %H:%M:%S')
   echo "${TIMESTAMP} [prolog] NHC processes finished and job can start" >> /var/log/nhc.log
   if [ -f /var/run/nhc/nhc.status ]; then
      exit 1
   else
      exit 0
   fi
elif [[ $PROLOG_RUN_NHC == 1 ]]; then
   /sched/scripts/run_nhc.sh
fi

