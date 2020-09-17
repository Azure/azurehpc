#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

GPU_MAP_FILE=/tmp/gpu_map_file
gpu_topo_dir=$DIR
exe_name=gpu_topo
START=58798080
END=62992384
INCREMENT=4194304

function list_to_array
{
OIFS=$IFS
IFS=","
array_order=($1)
IFS=$OIFS
}

function create_array_groups
{
second_group_indx_m1=$((second_group_indx-1))
num_gpus_m1=$((num_gpus-1))
array_order_gp1=()
array_order_gp2=()
for i in `seq 0 $second_group_indx_m1`
do
   array_order_gp1+=(${array_order[$i]}) 
done
for i in `seq $second_group_indx $num_gpus_m1`
do
   array_order_gp2+=(${array_order[$i]}) 
done
}

function swap_array_groups
{
   new_array_order=()
   for indx in ${array_order_gp2[@]}
   do
     new_array_order+=($indx)
   done
   for indx in ${array_order_gp1[@]}
   do
     new_array_order+=($indx)
   done
}

yum install -y cuda-demo-suite-10-1.x86_64
echo
if [ -f $GPU_MAP_FILE ]; then
   echo "`date`: Deleting $GPU_MAP_FILE"
   rm $GPU_MAP_FILE
fi

if [ ! -f /tmp/topo ]; then
   nvidia-smi topo -p2p n | grep OK | head -n 8 | awk '{$1=""; print $0}' | sed 's/ //' | tee /tmp/topo
fi

if [ ! -f $gpu_topo_dir/$exe_name ]; then
   echo "`date`: Compiling $gpu_topo_dir/$exe_name"
   g++ -o $gpu_topo_dir/gpu_topo $gpu_topo_dir/gpu_topo.cpp
fi
order=$($gpu_topo_dir/$exe_name /tmp/topo)
echo "`date`: Checking GPU mapping order $order"

list_to_array "$order"
num_gpus=${#array_order[@]}
second_group_indx=$((num_gpus/2))
first_group_gpuid=${array_order[0]}
second_group_gpuid=${array_order[$second_group_indx]}
second_group_gpuid=$(echo $second_group_gpuid | awk '{$1=$1;print}')

echo "`date`: Checking GPU ID=$first_group_gpuid"
bwtest_gpu1=$(taskset -c 0-1 /usr/local/cuda-10.1/extras/demo_suite/bandwidthTest --device=$first_group_gpuid  --dtoh --mode=range --start=$START --end=$END --increment=$INCREMENT | grep 62992384 | awk '{print $2}')
echo "`date`: GPU $first_group_gpuid BW to numa domain 0 = $bwtest_gpu1 MB/s"
echo "`date`: Checking GPU ID=$second_group_gpuid"
bwtest_gpu2=$(taskset -c 0-1 /usr/local/cuda-10.1/extras/demo_suite/bandwidthTest --device=$second_group_gpuid  --dtoh --mode=range --start=$START --end=$END --increment=$INCREMENT | grep 62992384 | awk '{print $2}')
echo "`date`: GPU $fourth_group_gpuid to numa domain 1 BW= $bwtest_gpu2 MB/s"

if (( $(echo "$bwtest_gpu1 < $bwtest_gpu2"| bc -l) )); then
   echo "`date`: $bwtest_gpu1 is lt $bwtest_gpu2"
   echo "`date`: Change GPU mapping to numa domains"
   create_array_groups
   swap_array_groups
   echo "`date`: GPU mapping $(echo ${new_array_order[@]} | sed 's/ /,/g')"
   echo $(echo ${new_array_order[@]} | sed 's/ /,/g') > $GPU_MAP_FILE
else
   echo "`date`: GPU mapping $order"
   echo $order > $GPU_MAP_FILE
fi
echo "`date`: GPU mapping is written to $GPU_MAP_FILE"
