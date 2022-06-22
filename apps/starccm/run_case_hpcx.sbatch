#!/bin/bash

#SBATCH --time=20:00:00
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=96
#SBATCH --mem=400gb
#SBATCH --job-name=Starccm
#SBATCH --exclusive
#SBATCH -o %x_%j.log

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/shared/apps}
DATA_DIR=${DATA_DIR:-/shared/data/starccm}
CASE=${CASE:-lemans_poly_17m.amg}
OMPI=${OMPI:-openmpi4}
STARCCM_VERSION=${STARCCM_VERSION:-15.02.009}
PODKEY=""

# PODKEY is required (pass in as environment variable)
if [ -z "$PODKEY" ];
then
    echo "Error: the PODKEY environment variable is not set"
    exit 1
fi

INSTALL_DIR=$APP_INSTALL_DIR/starccm
STARCCM_CASE=$DATA_DIR/${CASE}.sim

export PATH=$INSTALL_DIR/$STARCCM_VERSION/STAR-CCM+$STARCCM_VERSION/star/bin:$PATH
export CDLMD_LICENSE_FILE=1999@flex.cd-adapco.com

## SLURM: ====> Job Node List (DO NOT MODIFY)
echo "Slurm nodes assigned :$SLURM_JOB_NODELIST"
echo "SLURM_JOBID="$SLURM_JOBID
echo "SLURM_JOB_NODELIST"=$SLURM_JOB_NODELIST
echo "SLURM_NNODES"=$SLURM_NNODES
echo "SLURMTMPDIR="$SLURMTMPDIR
echo "working directory = "$SLURM_SUBMIT_DIR
echo "SLURM_NTASKS="$SLURM_NTASKS

mkdir -p $SLURM_SUBMIT_DIR/$SLURM_JOBID
cd $SLURM_SUBMIT_DIR/$SLURM_JOBID

#Prep host file
scontrol show hostname $SLURM_NODELIST | tr 'ec' 'ic'> machinefile_${SLURM_JOB_ID}

NODES=$SLURM_NNODES
PPN=$SLURM_NTASKS_PER_NODE
CORES=$SLURM_NTASKS

export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
source /opt/hpcx-*-x86_64/hpcx-init.sh
hpcx_load
export OPENMPI_DIR=$HPCX_MPI_DIR

BM_OPT="-preclear -preits 40 -nits 20 -nps $CORES"
if [ "$CASE" = "EmpHydroCyclone_30M" ]
then
    BM_OPT="-preits 1 -nits 1 -nps $CORES"
elif [ "$CASE" = "kcs_with_physics" ]
then
    BM_OPT="-preits 40 -nits 20 -nps $CORES"
fi

echo $BM_OPT
echo PPN=$PPN

echo "Running Starccm Benchmark case : [${starccm_case}], Nodes: ${NODES} (Total Cores: ${CORES})"

if [ "$PPN" == "120" ]
then
    mppflags="--bind-to cpulist:ordered --cpu-set 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119 --report-bindings -mca mca_base_env_list UCX_TLS=dc_x,sm,self;UCX_IB_SL=1;UCX_DC_MLX5_NUM_DCI=15"
elif [ "$PPN" == "118" ]
then
    mppflags="--bind-to cpulist:ordered --cpu-set 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118 --report-bindings -mca mca_base_env_list UCX_TLS=dc_x,sm,self;UCX_IB_SL=1;UCX_DC_MLX5_NUM_DCI=15"
elif [ "$PPN" == "116" ]
then
    mppflags="--bind-to cpulist:ordered --cpu-set 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118 --report-bindings -mca mca_base_env_list UCX_TLS=dc_x,sm,self;UCX_IB_SL=1;UCX_DC_MLX5_NUM_DCI=15"
elif [ "$PPN" == "96" ]
then
    mppflags="--bind-to cpulist:ordered --cpu-set 0,1,2,3,4,5,8,9,10,11,12,13,16,17,18,19,20,21,24,25,26,27,28,29,30,31,32,33,34,35,38,39,40,41,42,43,46,47,48,49,50,51,54,55,56,57,58,59,60,61,62,63,64,65,68,69,70,71,72,75,76,77,78,79,80,81,84,85,86,87,88,89,90,91,92,93,94,95,98,99,100,101,102,103,106,107,108,109,110,111,114,115,116,117,118,119 --report-bindings -mca mca_base_env_list UCX_TLS=dc_x,sm,self;UCX_IB_SL=1;UCX_DC_MLX5_NUM_DCI=15"
elif [ "$PPN" == "64" ]
then
    mppflags="--bind-to cpulist:ordered --cpu-set 0,1,2,3,8,9,10,11,16,17,18,19,24,25,26,27,30,31,32,33,38,39,40,41,46,47,48,49,54,55,56,57,60,61,62,63,68,69,70,71,76,77,78,79,84,85,86,87,90,91,92,93,98,99,100,101,106,107,108,109,114,115,116,117 --report-bindings -mca mca_base_env_list UCX_TLS=dc_x,sm,self;UCX_IB_SL=1;UCX_DC_MLX5_NUM_DCI=15"
elif [ "$PPN" == "32" ]
then
    mppflags="--bind-to cpulist:ordered --cpu-set 0,1,8,9,16,17,24,25,30,31,38,39,46,47,54,55,60,61,68,69,76,77,84,85,90,91,98,99,106,107,114,115 --report-bindings -mca mca_base_env_list UCX_TLS=dc_x,sm,self;UCX_IB_SL=1;UCX_DC_MLX5_NUM_DCI=15"
elif [ "$PPN" == "16" ]
then
    mppflags="--bind-to cpulist:ordered --cpu-set 0,8,16,24,30,38,46,54,60,68,76,84,90,98,106,114 --report-bindings -mca mca_base_env_list UCX_TLS=dc_x,sm,self;UCX_IB_SL=1;UCX_DC_MLX5_NUM_DCI=15"
#    mppflags="--bind-to cpulist:ordered --cpu-set 0,8,16,24,32,40,48,56,64,72,80,88,96,104,112,120 --report-bindings"
else
    echo "No defined setting for Core count: $CORES"
    mppflags="--report-bindings"
fi

starccm+ \
    -np $CORES \
    -v \
    -machinefile machinefile_${SLURM_JOB_ID} \
    -power \
    -podkey "$PODKEY" \
    -rsh ssh \
    -mpi openmpi4 \
    -cpubind off \
    -ldlibpath $LD_LIBRARY_PATH \
    -fabric ucx \
    -xsystemucx \
    -mppflags "$mppflags" \
    $STARCCM_CASE -benchmark "$BM_OPT"

DATE=$(date +"%Y%m%d-%H%M%S.%N")
cp $CASE-*.xml $SLURM_SUBMIT_DIR/${CASE}-hpcx-${NODES}n-${PPN}cpn-${CORES}c-${DATE}.xml
