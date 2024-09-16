#!/bin/bash
groupname=$1
vmlist=$2
ossnum=$3
drivenum=$4

#create the drives first before attachint to vmss
drivecount=$(($drivenum*$ossnum))

for ((num=1; num<=$drivecount; num++)); do
	az disk create -g $groupname -n "lustredrive$num" --size-gb 1024 &
done

sleep 60 # to ensure all drives are made

#Now use the created drives
index=0
lustrecnt=1

idlisttmp=$(az vmss list-instances --resource-group $groupname --name lustre |grep providers/Microsoft.Compute/virtualMachineScaleSets/lustre/virtualMachines | awk -F "virtualMachines/" '{print $2}' | sed '/networkInterfaces/d'| sed 's/["].*$//')

idlist=($idlisttmp)

for vmname in ${vmlist[@]}; do
	((index++))
	if [ $index -gt 0 ] ; then
	for ((diskid=1; diskid<=$drivenum; diskid++)); do
		az vmss disk attach --vmss-name lustre --disk lustredrive${lustrecnt} --sku Premium_LRS --instance-id ${idlist[$index]} --resource-group $groupname
		((lustrecnt++))
	done
	fi
done

