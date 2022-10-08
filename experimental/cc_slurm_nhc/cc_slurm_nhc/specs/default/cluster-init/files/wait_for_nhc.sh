#!/bin/bash

pid=`ps -ef | grep -v kill_nhc | grep nhc | tr -s ' ' | cut -d ' ' -f2 | head -n 1`

while ps -p $pid > /dev/null 2>&1
do
    sleep 10
    TIMESTAMP=$(/bin/date '+%Y%m%d %H:%M:%S')
    echo "${TIMESTAMP} [prolog] NHC processes still running" >> /var/log/nhc.log
done

TIMESTAMP=$(/bin/date '+%Y%m%d %H:%M:%S')
echo "${TIMESTAMP} [prolog] NHC processes finished and job can start" >> /var/log/nhc.log
exit 0
