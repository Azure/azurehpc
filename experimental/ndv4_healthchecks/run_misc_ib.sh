#!/bin/bash

#expect 8 active devives and 200 Gbps

HOSTNAME=`hostname`
OUT_DIR=/shared/home/cycleadmin/healthchecks/misc_ib/out

num_active=`ibstat | grep -A10 mlx5_ib | grep Active`
num_up=`ibstat | grep -A10 mlx5_ib | grep Linkup`
num_good=`ibstat | grep -A10 mlx5_ib | grep "Rate: 200"`


echo "num_active= $num_active" > ${OUT_DIR}/${HOSTNAME}_num_active.out
value_active=`grep Active ${OUT_DIR}/${HOSTNAME}_num_active.out | wc -l`
echo "value= $value_active" >> ${OUT_DIR}/${HOSTNAME}_num_active.out
echo "num_up= $num_active" > ${OUT_DIR}/${HOSTNAME}_num_up.out
value_up=`grep Active ${OUT_DIR}/${HOSTNAME}_num_up.out | wc -l`
echo "value= $value_up" >> ${OUT_DIR}/${HOSTNAME}_num_up.out
echo "num_good= $num_good" > ${OUT_DIR}/${HOSTNAME}_num_good.out
value_good=`grep 200 ${OUT_DIR}/${HOSTNAME}_num_good.out | wc -l`
echo "value= $value_good" >> ${OUT_DIR}/${HOSTNAME}_num_good.out
