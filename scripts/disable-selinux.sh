#!/bin/bash

# Check to see which OS this is running on.
os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')

# Script to be run on all compute nodes
if [ "$os_release" == "centos" ];then
   # set to permissive for now (until reboot)
   setenforce 0
   # prep to have selinux disabled after reboot
   sed -i 's/SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config
elif [ "$os_release" == "ubuntu" ];then
   echo "Not needed for $os_release"
fi
