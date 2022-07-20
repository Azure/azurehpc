#!/bin/bash

# Kill NHC processes
pkill -9 -f /usr/sbin/nhc
TIMESTAMP=$(/bin/date '+%Y%m%d %H:%M:%S')
echo "${TIMESTAMP} [prolog] NHC processes killed at job start" >> /var/log/nhc.log

exit 0
