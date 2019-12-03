#!/bin/bash

install_dir=/apps

cd $PBS_O_WORKDIR

export ANSYSLMD_LICENSE_FILE=1055@localhost
export ANSYSLI_SERVERS=2325@localhost
export FLUENT_HOSTNAME=`hostname`
export APPLICATION=fluent
export VERSION=v193
export MPI=hpcx

MODEL=f1_racecar_140m

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

export PATH=$install_dir/ansys_inc/v193/fluent/bin:$PATH
export FLUENT_PATH=$install_dir/ansys_inc/v193/fluent

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
    -mpi=openmpi \
    -mpiopt="-mca btl ^vader,tcp,openib --mca opal_warn_on_missing_libcuda 0 -mca plm_rsh_no_tree_spawn 1 -mca plm_rsh_num_concurrent 300 -mca plm_base_verbose 5 -mca routed_base_verbose 5 -bind-to core -map-by ppr:$ppr:numa -report-bindings -x UCX_NET_DEVICES=mlx5_0:1 -x UCX_IB_PKEY=$PKEY -mca btl_openib_if_include mlx5_0:1 -x UCX_TLS=ud,sm,self" \
    -cnf=hosts \
    -affinity=$aff \
    -feature_parallel_preferred=$ans_lic_type

# Clean up
unlink libopen-rte.so.4
unlink libopen-pal.so.4
unlink libmpi.so.1

