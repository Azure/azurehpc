#!/bin/bash
RELEASE=$(cat /etc/redhat-release | cut -d' ' -f4)
echo $RELEASE
yum --releasever=$RELEASE install -y kernel kernel-tools kernel-headers kernel-devel
