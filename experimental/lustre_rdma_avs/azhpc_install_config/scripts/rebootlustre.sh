#!/bin/bash
vmlist=$1
osscount=$2
totalcount=$((osscount+2))
index=0
#prep headnode
cp -r /share/home/hpcuser/.ssh /root/
echo "vmlist is ${vmlist[@]}"

#needs to be done sequentially
for vmname in ${vmlist[@]}; do
	echo "Rebooting $vmname"
	ssh hpcuser@${vmname} "sudo reboot 2>/dev/null; exit 2>/dev/null" 2>/dev/null
	index=$((index+1))
done
exit 0
