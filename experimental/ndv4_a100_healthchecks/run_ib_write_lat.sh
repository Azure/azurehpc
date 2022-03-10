#!/bin/bash
set -ex

#Expected IB latency < 2 us

OUT_DIR=/shared/home/cycleadmin/healthchecks/ib_lat/out
HOSTNAME=`hostname`
IB_WRITE_LAT_EXE=/shared/home/cycleadmin/healthchecks/perftest-4.5/ib_write_lat

DURATION=10
BW_OPTIONS="-D ${DURATION} -x 0 -F"

GPU_NUMA=( 1 1 0 0 3 3 2 2 )

for device in  {0..3}
do
    device_peer=$(( $device + 4 ))
    numa1=${GPU_NUMA[$device]}
    numa2=${GPU_NUMA[$device_peer]}
    numactl -N $numa1 -m $numa1  $IB_WRITE_LAT_EXE ${BW_OPTIONS} -d mlx5_ib${device} > /dev/null &
    sleep 5
    numactl -N $numa2 -m $numa2 $IB_WRITE_LAT_EXE ${BW_OPTIONS} -d mlx5_ib${device_peer}  $HOSTNAME 2>&1 | tee ${OUT_DIR}/${HOSTNAME}_write-lat-$device-$device_peer.log_$$
done
