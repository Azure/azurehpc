#!/bin/bash

# Expected bandwidth > 24GB/s

BANDWIDTHTEST_EXE=~/bandwidthTest
OUT_DIR=~/healthchecks/bandwidthtest/out
HOSTNAME=`hostname`

numactl --cpunodebind=1 --membind=1 $BANDWIDTHTEST_EXE --dtoh --htod --device=0 >& ${OUT_DIR}/${HOSTNAME}_gpuid_0.out
sleep 2
numactl --cpunodebind=1 --membind=1 $BANDWIDTHTEST_EXE --dtoh --htod --device=1 >& ${OUT_DIR}/${HOSTNAME}_gpuid_1.out
sleep 2
numactl --cpunodebind=0 --membind=0 $BANDWIDTHTEST_EXE --dtoh --htod --device=2 >& ${OUT_DIR}/${HOSTNAME}_gpuid_2.out
sleep 2
numactl --cpunodebind=0 --membind=0 $BANDWIDTHTEST_EXE --dtoh --htod --device=3 >& ${OUT_DIR}/${HOSTNAME}_gpuid_3.out
sleep 2
numactl --cpunodebind=3 --membind=3 $BANDWIDTHTEST_EXE --dtoh --htod --device=4 >& ${OUT_DIR}/${HOSTNAME}_gpuid_4.out
sleep 2
numactl --cpunodebind=3 --membind=3 $BANDWIDTHTEST_EXE --dtoh --htod --device=5 >& ${OUT_DIR}/${HOSTNAME}_gpuid_5.out
sleep 2
numactl --cpunodebind=2 --membind=2 $BANDWIDTHTEST_EXE --dtoh --htod --device=6 >& ${OUT_DIR}/${HOSTNAME}_gpuid_6.out
sleep 2
numactl --cpunodebind=2 --membind=2 $BANDWIDTHTEST_EXE --dtoh --htod --device=7 >& ${OUT_DIR}/${HOSTNAME}_gpuid_7.out
