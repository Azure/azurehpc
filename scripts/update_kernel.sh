#!/bin/bash
RELEASE=$(cat /etc/redhat-release | cut -d' ' -f4)
echo $RELEASE
repo=updates
status=$(yum repoinfo updates-openlogic | grep enabled)
if [ "$status" != "" ]; then
    repo=updates-openlogic
fi
echo "repo to install kernel headers is $repo"
yum install -y --disablerepo=* --enablerepo=$repo --releasever=$RELEASE kernel kernel-tools kernel-headers kernel-devel

