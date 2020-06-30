#!/bin/bash
#rpm -e neohost-backend neohost-sdk-1.5.0-102.x86_64
yum -y remove neohost-backend neohost-sdk-1.5.0-102.x86_64 2>/dev/null
/usr/sbin/ofed_uninstall.sh
sleep 5
exit 0
