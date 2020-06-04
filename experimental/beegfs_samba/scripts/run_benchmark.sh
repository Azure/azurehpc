#!/bin/bash

vm_name=$1
vm_instances=$2
njobs=$3
ndepth=$4

ts=$(date +"%Y%m%d%H%M")

nodes=()
for n in $(seq -f "%04g" 1 $vm_instances); do
    nodes+=(${vm_name}${n})
done

azhpc-run -c scripts/config.json -n $(echo ${nodes[@]} | tr ' ' ',') '.\mount_beegfs.ps1; C:\\ProgramData\\chocolatey\\bin\\fio.exe --name=Z:\$(hostname)-read-4m-'$ts' --rw=read --direct=1 --bs=4M --numjobs='$njobs' --iodepth='$ndepth' --size=16G --runtime=300'
azhpc-run -c scripts/config.json -n $(echo ${nodes[@]} | tr ' ' ',') '.\mount_beegfs.ps1; C:\\ProgramData\\chocolatey\\bin\\fio.exe --name=Z:\$(hostname)-write-4m-'$ts' --rw=write --direct=1 --bs=4M --numjobs='$njobs' --iodepth='$ndepth' --size=16G --runtime=300'