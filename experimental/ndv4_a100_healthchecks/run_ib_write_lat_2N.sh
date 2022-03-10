#!/bin/bash
set -ex

#Expected IB latency < 3 us

host1=$1
host2=$2

gpu_device_id=0
OUT_DIR=/shared/home/cycleadmin/healthchecks/ib_lat/out
IB_WRITE_LAT_EXE=/shared/home/cycleadmin/healthchecks/perftest-4.5/ib_write_lat

DURATION=10
BW_OPTIONS="-D ${DURATION} -x 0 -F"

GPU_NUMA=( 1 1 0 0 3 3 2 2 )

numa=${GPU_NUMA[$gpu_device_id]}
ssh $host1 "numactl -N $numa -m $numa $IB_WRITE_LAT_EXE ${BW_OPTIONS} -d mlx5_ib${gpu_device_id} > /dev/null &"
sleep 15
ssh $host2 "numactl -N $numa -m $numa $IB_WRITE_LAT_EXE ${BW_OPTIONS} -d mlx5_ib${gpu_device_id}  $host1  2>&1 | tee ${OUT_DIR}/${host1}_
${host2}_write-lat-${gpu_device_id}.log_$$"
