#!/bin/sh
#
#PBS -N nwchem_h2o_freq
#PBS -l select=1:ncpus=4:mpiprocs=4
#PBS -koed
#PBS -joe
#PBS -l walltime=800
#
APP_NAME=nwchem
NW_DATA=h2o_freq
SHARED_DATA=/data
DATA_DIR=${SHARED_DATA}/${APP_NAME}
#
export MODULEFILE=/opt/hpcx:$MODULEFILE
module load gcc-8.2.0
module load hpcx
module load nwchem_6.8
#
CORES=`cat $PBS_NODEFILE | wc -l`
#
get_ib_pkey()
{
    key0=$(cat /sys/class/infiniband/mlx5_0/ports/1/pkeys/0)
    key1=$(cat /sys/class/infiniband/mlx5_0/ports/1/pkeys/1)

    if [ $(($key0 - $key1)) -gt 0 ]; then
        export IB_PKEY=$key0
    else
        export IB_PKEY=$key1
    fi

    export UCX_IB_PKEY=$(printf '0x%04x' "$(( $IB_PKEY & 0x0FFF ))")
}
#
cd $SHARED_DATA/$APP_NAME/$NW_DATA

source /opt/intel/impi/*/bin64/mpivars.sh
export MPI_ROOT=$I_MPI_ROOT
export PATH=/opt/NWChem-6.8/bin:$PATH

ln -s /opt/NWChem-6.8/data/default.nwchemrc $HOME/.nwchemrc 

cd $DATA_DIR

mpirun \
    -np $CORES \
    --hostfile $PBS_HOSTFILE \
    --map-by core \
    --report-bindings \
    -x UCX_IB_PKEY=${UCX_IB_PKEY} \
     nwchem \
    ./${NW_DATA}.nw \
    > ./${NW_DATA}.out

fname=./h2o_freq.out
cpu_str=$(grep "Total times" $fname | awk '{print $4}')
cpu_str_s=${cpu_str::-1}
cpu_time=$(bc <<< "$cpu_str_s * $CORES")
wall_str=$(grep "Total times" $fname | awk '{print $6}')
wall_time=${wall_str::-1}
memory_heap_MB=$(grep "maximum total M-bytes" $fname | awk '{print $4}')
memory_stack_MB=$(grep "maximum total M-bytes" $fname | awk '{print $5}')
memory_MB=$(bc <<< "$memory_heap_MB + $memory_stack_MB")

cat <<EOF >${APP_NAME}.json
{
"model": "h2o_freq",
"cpu_time": "$cpu_time",
"clock_time": "$wall_time",
"memory": "$memory_MB"
}
EOF
