#!/bin/bash
groupname=$1
vmlist=$2
ossnum=$3

totalcount=$(($ossnum+2))
index=0

#prep headnode
cp -r /share/home/hpcuser/.ssh /root/

#needs to be done sequentially
for vmname in ${vmlist[@]}; do
	if [ $index -lt $totalcount ] ; then
	echo "Rebooting $vmname"
	ssh hpcuser@${vmname} "sudo reboot 2>/dev/null; exit 2>/dev/null" 2>/dev/null
        fi
done
exit 0 # to ensure no errors are thrown

