#!/bin/bash

# Expected bandwidth > 24GB/s

BANDWIDTHTEST_EXE=~/bandwidthTest
OUT_DIR=~/healthchecks/bandwidthtest/out
HOSTNAME=`hostname`

for gpu_id in {0..7}
do
   numactl --cpunodebind=1 --membind=1 ./bandwidthTest --dtoh --htod --device=${gpu_id} $BANDWIDTHTEST_EXE >& ${OUT_DIR}/${HOSTNAME}_gpuid_0.out
done
numactl --cpunodebind=1 --membind=1 ./bandwidthTest --dtoh --htod --device=0 $BANDWIDTHTEST_EXE >& ${OUT_DIR}/${HOSTNAME}_gpuid_0.out
sleep 2
numactl --cpunodebind=1 --membind=1 ./bandwidthTest --dtoh --htod --device=1 $BANDWIDTHTEST_EXE >& ${OUT_DIR}/${HOSTNAME}_gpuid_1.out
sleep 2
numactl --cpunodebind=0 --membind=0 ./bandwidthTest --dtoh --htod --device=2 $BANDWIDTHTEST_EXE >& ${OUT_DIR}/${HOSTNAME}_gpuid_2.out
sleep 2
numactl --cpunodebind=0 --membind=0 ./bandwidthTest --dtoh --htod --device=3 $BANDWIDTHTEST_EXE >& ${OUT_DIR}/${HOSTNAME}_gpuid_3.out
sleep 2
numactl --cpunodebind=3 --membind=3 ./bandwidthTest --dtoh --htod --device=4 $BANDWIDTHTEST_EXE >& ${OUT_DIR}/${HOSTNAME}_gpuid_4.out
sleep 2
numactl --cpunodebind=3 --membind=3 ./bandwidthTest --dtoh --htod --device=5 $BANDWIDTHTEST_EXE >& ${OUT_DIR}/${HOSTNAME}_gpuid_5.out
sleep 2
numactl --cpunodebind=2 --membind=2 ./bandwidthTest --dtoh --htod --device=6 $BANDWIDTHTEST_EXE >& ${OUT_DIR}/${HOSTNAME}_gpuid_6.out
sleep 2
numactl --cpunodebind=2 --membind=2 ./bandwidthTest --dtoh --htod --device=7 $BANDWIDTHTEST_EXE >& ${OUT_DIR}/${HOSTNAME}_gpuid_7.out
