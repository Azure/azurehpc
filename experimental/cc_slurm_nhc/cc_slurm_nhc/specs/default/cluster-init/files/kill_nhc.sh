#!/bin/bash

AZNHC_CONT_NAME='aznhc'
# Stop AzNHC container
docker stop $AZNHC_CONT_NAME
TIMESTAMP=$(/bin/date '+%Y%m%d %H:%M:%S')
echo "${TIMESTAMP} [prolog] NHC processes killed at job start" >> /var/log/nhc.log

exit 0
