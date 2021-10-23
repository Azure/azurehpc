#!/bin/bash
set -ex

#Expected IB Bandwidth > 180GB/s

OUT_DIR=/shared/home/cycleadmin/healthchecks/IB/out
HOSTNAME=`hostname`
#IB_WRITE_BW=/usr/bin/ib_write_bw
IB_WRITE_BW_EXE=/shared/home/cycleadmin/perftest-4.5/ib_write_bw

DURATION=10
BW_OPTIONS="-s $(( 1 * 1024 * 1024 )) -D ${DURATION} -x 0 -F --report_gbits"


for device in  {0..3}
do
    device_peer=$(( $device + 4 ))
    numa1=$(( $device / 2 ))
    numa2=$(( $device_peer / 2 ))
    numactl -c ${numa1} $IB_WRITE_BW_EXE ${BW_OPTIONS} --use_cuda=${device} -d mlx5_ib${device} > /dev/null &
    sleep 5
    numactl -c ${numa2} $IB_WRITE_BW_EXE ${BW_OPTIONS} --use_cuda=${device_peer} -d mlx5_ib${device_peer}  $HOSTNAME 2>&1 | tee ${OUT_DIR}/${HOSTNAME}_write-bw-$device-$device_peer.log
done
