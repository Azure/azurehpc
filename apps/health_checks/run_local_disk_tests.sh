#!/bin/bash

if [[ ! -d /mnt/resource_nvme && -e /dev/nvme0n1 ]];then
    sudo mkfs.ext4 /dev/nvme0n1
    sudo mkdir -p /mnt/resource_nvme
    sudo mount /dev/nvme0n1 /mnt/resource_nvme
    sudo chmod 775 /dev/nvme0n1
    sudo chmod 777 /mnt/resource_nvme/
fi

sudo yum install -y fio

#FILESYSTEM=${1:-$FILESYSTEM}
set -o pipefail

RUNTIME=600
HOSTNAME=`hostname`

OUTFILE="fio_${HOSTNAME}_results.out"
echo "FIO Results for $HOSTNAME" > $OUTFILE

for FILESYSTEM in /mnt/resource /mnt/resource_nvme
do
    DIRECTORY=${FILESYSTEM}/testing
    mkdir $DIRECTORY
    NUMJOBS=1

#    for BS in 4K 4M
    for BS in 4M
    do
       if [ $BS == "4K" ]; then
           SIZE=128M
       else
           SIZE=2G
       fi
       for RW in write read
       do
#           for DIRECTIO in 0 1
           for DIRECTIO in 1
           do
               echo -n "File system: $FILESYSTEM, Operation: $RW, Direct IO: $DIRECTIO, Block Size: $BS, Size: $SIZE - " >> $OUTFILE
               sudo bash -c "sync; echo 3 > /proc/sys/vm/drop_caches"
               fio --name=${RW}_${SIZE} --directory=$DIRECTORY --direct=$DIRECTIO --size=$SIZE --bs=$BS --rw=${RW} --numjobs=$NUMJOBS --group_reporting --runtime=${RUNTIME} --output=fio_${HOSTNAME}_${RW}_${SIZE}_${BS}_${NUMJOBS}_${DIRECTIO}.out
               rm ${DIRECTORY}/*
               sync
               sleep 1
               value=$(grep -E 'READ:|WRITE:' fio_${HOSTNAME}_${RW}_${SIZE}_${BS}_${NUMJOBS}_${DIRECTIO}.out | awk '{print $3}')
               tmp=${value#"("}
               tmp=${tmp%"),"}
               echo $tmp >> $OUTFILE
               rm -rf fio_${HOSTNAME}_${RW}_${SIZE}_${BS}_${NUMJOBS}_${DIRECTIO}.out
               echo ""
           done
       done
   done
done
