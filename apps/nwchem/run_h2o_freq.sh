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
SHARED_APPS=/apps
SHARED_DATA=/data
DATA_DIR=${SHARED_DATA}/${APP_NAME}
BIN_DIR=${SHARED_APPS}/${APP_NAME}/bin
#
export MODULEPATH=/opt/hpcx-v2.4.1-gcc-MLNX_OFED_LINUX-4.6-1.0.1.1-redhat7.6-x86_64/modulefiles:${SHARED_APPS}/modulefiles:$MODULEPATH
module load gcc-8.2.0
module load hpcx
module load nwchem_6.8
#
CORES=`cat $PBS_NODEFILE | wc -l`
#
PKEY=$(grep -v -e 0000 -e 0x7fff --no-filename /sys/class/infiniband/mlx5_0/ports/1/pkeys/*)
PKEY=${PKEY/0x8/0x0}

#
cd $SHARED_DATA/$APP_NAME

ln -s ${SHARED_APPS}/nwchem/data/default.nwchemrc $HOME/.nwchemrc 

cd $DATA_DIR

mpirun \
    -np $CORES \
    --hostfile $PBS_NODEFILE \
    --map-by core \
    --report-bindings \
    -x UCX_IB_PKEY=$PKEY \
     ${BIN_DIR}/nwchem \
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
