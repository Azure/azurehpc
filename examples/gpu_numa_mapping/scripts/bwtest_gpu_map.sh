#!/bin/bash

num_gpus=$(lspci | grep NVIDIA | wc -l)
BWTEST_FILE=/tmp/bwtest_file
GPU_MAP_FILE=/tmp/gpu_map_file
START=58798080
END=67186688
INCREMENT=4194304

yum install -y cuda-demo-suite-10-1.x86_64

echo
echo "`date`: Hostname=`hostname`"
echo "`date`: Found $num_gpus GPUs"

if [  -f $BWTEST_FILE ]; then
   echo "`date`: Deleting $BWTEST_FILE"
   rm $BWTEST_FILE
fi
if [ -f $GPU_MAP_FILE ]; then
   echo "`date`: Deleting $GPU_MAP_FILE"
   rm $GPU_MAP_FILE
fi
num_gpu_m1=$((num_gpus-1))
for gpuid in `seq 0 $num_gpu_m1`
do
echo "`date`: Checking GPU: $gpuid"
bwtest_str=$(taskset -c 0-1 /usr/local/cuda-10.1/extras/demo_suite/bandwidthTest --device=$gpuid  --dtoh --mode=range --start=$START --end=$END --increment=$INCREMENT | grep 62992384 | awk '{print $2}')
echo "$gpuid $bwtest_str" >> $BWTEST_FILE
done

sort -r -k 2 -o $BWTEST_FILE $BWTEST_FILE

gpu_array=()
while read line
do
   value=$(echo $line | awk '{print $1}')
   gpu_array+=($value)
done < $BWTEST_FILE

gpu_map=$(echo ${gpu_array[@]} | sed 's/ /,/g')

echo
echo $gpu_map 
echo $gpu_map > $GPU_MAP_FILE
