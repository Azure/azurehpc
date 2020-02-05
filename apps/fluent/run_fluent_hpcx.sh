#!/bin/bash

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/apps}
DATA_DIR=${DATA_DIR:-/data}
MODEL=${MODEL:-sedan_4m}
OMPI=${OMPI:-openmpi}
FLUENT_VERSION=${FLUENT_VERSION:-v195}
LIC_SRV=${LIC_SRV:-localhost}

export ANSYSLMD_LICENSE_FILE=1055@${LIC_SRV}
export ANSYSLI_SERVERS=2325@${LIC_SRV}
export FLUENT_HOSTNAME=`hostname`
export APPLICATION=fluent
export VERSION=$FLUENT_VERSION

cd $PBS_O_WORKDIR

CORES=`cat $PBS_NODEFILE | wc -l`
NODES=`cat $PBS_NODEFILE | sort | uniq | wc -l`
cat $PBS_NODEFILE | uniq -c | awk '{ print $2 ":" $1 }' > hosts
PPN=`cat $PBS_NODEFILE | uniq -c | head -1 | awk '{ print $1 }'`
DATE=`date +"%Y%m%d_%H%M%S"`
PKEY=$(grep -v -e 0000 -e 0x7fff --no-filename /sys/class/infiniband/mlx5_0/ports/1/pkeys/*)
PKEY=${PKEY/0x8/0x0}
echo "PKEY: $PKEY"

HPCX_DIR=$(ls -atr /opt | grep hpcx | tail -n1)
source /etc/profile 
module use /opt/$HPCX_DIR/modulefiles
module load hpcx

export PATH=$APP_INSTALL_DIR/ansys_inc/${FLUENT_VERSION}/fluent/bin:$PATH
export FLUENT_PATH=$APP_INSTALL_DIR/ansys_inc/${FLUENT_VERSION}/fluent
export OPENMPI_ROOT=$HPCX_MPI_DIR

RUNDIR=$PWD
rm -f $RUNDIR/lib*.so*
ln -s $MPI_HOME/lib/libmpi.so $RUNDIR/libmpi.so.1
ln -s $MPI_HOME/lib/libopen-pal.so $RUNDIR/libopen-pal.so.4
ln -s $MPI_HOME/lib/libopen-rte.so $RUNDIR/libopen-rte.so.4
export LD_LIBRARY_PATH=${RUNDIR}:${LD_LIBRARY_PATH}

# Setup SSH tunnel to license server. Requires ssh keys to be setup to license server
#ssh -fNT -g -L 1055:localhost:1055 -L 2325:localhost:2325 -L 58878:localhost:58878 user@ip-address

if [ "$CORES" -gt 4800 ]; then
    ans_lic_type=anshpc_pack
else
    ans_lic_type=anshpc
fi

num_cpus="$(cat /proc/cpuinfo |grep ^processor | wc -l)"
if [ "$PPN" -lt "$num_cpus" ]; then
    aff=off
else
    aff=on
fi

echo "License Type: $ans_lic_type"

numa_domains="$(numactl -H |grep available|cut -d' ' -f2)"
ppr=$(( ($PPN + $numa_domains - 1) / $numa_domains ))

fluentbench.pl \
    -path=$FLUENT_PATH \
    -ssh \
    -norm \
    -nosyslog \
    $MODEL \
    -t$CORES \
    -pinfiniband \
    -mpi=$OMPI \
    -mpiopt="--mca opal_warn_on_missing_libcuda 0 -mca plm_rsh_no_tree_spawn 1 -mca plm_rsh_num_concurrent 300 -bind-to core -map-by node -report-bindings " \
    -cnf=hosts \
    -affinity=$aff \
    -feature_parallel_preferred=$ans_lic_type

# Clean up
unlink libopen-rte.so.4
unlink libopen-pal.so.4
unlink libmpi.so.1
