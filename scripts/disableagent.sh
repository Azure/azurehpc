#!/bin/bash

#ifconfig eth1 down

# Check to see which OS this is running on. 
os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
os_maj_ver=$(cat /etc/os-release | grep "^VERSION_ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
echo "OS Release: $os_release"
echo "OS Major Version: $os_maj_ver"

if [ "$os_release" == "centos" ];then
    systemctl stop waagent
elif [ "$os_release" == "ubuntu" ];then
    systemctl stop walinuxagent
fi
