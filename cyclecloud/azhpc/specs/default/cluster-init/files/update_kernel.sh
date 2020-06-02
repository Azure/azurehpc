#!/bin/bash
RELEASE=$(cat /etc/redhat-release | cut -d' ' -f4)
echo $RELEASE
yum --releasever=$RELEASE --disablerepo=openlogic install -y kernel kernel-tools kernel-headers kernel-devel
