#!/bin/bash
#SBATCH --job-name=wrf
#SBATCH --partition=hpc
###SBATCH --ntasks=120
#SBATCH --ntasks-per-node=120
#SBATCH --nodes=2
#SBATCH --exclusive
#SBATCH --output=log-hello_mpi_test.out

SKU_TYPE=${1:-$SKU_TYPE}
SKU_TYPE=${SKU_TYPE:-"hbv3"}
INPUTDIR=${2:-$INPUTDIR}
INPUTDIR=${INPUTDIR:-"/apps/hbv3/wrf-openmpi/WRF-4.1.5/run"}

echo "INPUTDIR:" $INPUTDIR
echo "SKU_TYPE:" $SKU_TYPE

SHARED_APP=${SHARED_APP:-/apps}

if [ -z $INPUTDIR ]; then
    echo "INPUTDIR parameter is required"
    exit 1
fi

if ! rpm -q python3; then
    sudo yum install -y python3
fi

echo "source envs"
source /data/azurehpc/apps/wrf/env-variables hbv3

# Run the program with mpirun
echo "SLURM_JOB_NODELIST:" $SLURM_JOB_NODELIST
echo "SLURM_NTASKS:" $SLURM_NTASKS

scontrol show hostname $SLURM_JOB_NODELIST > hostfile.txt
NPROCS=`cat hostfile.txt | wc -l`
echo "NPROCS:" $NPROCS

echo "SLURM_SUBMIT_DIR:" $SLURM_SUBMIT_DIR
echo "WRFROOT:" ${WRFROOT}
echo "INPUTDIR: " ${INPUTDIR}

cd $SLURM_SUBMIT_DIR
ln -s ${WRFROOT}/run/* .
cp ${INPUTDIR}/*_d01 .
cp ${INPUTDIR}/namelist.input .

echo "LD_PRELOAD:" $LD_PRELOAD
mpi_options="-x LD_LIBRARY_PATH "
if [ -n $LD_PRELOAD ]; then
    mpi_options+="-x LD_PRELOAD"
fi
echo "mpi_options:" $mpi_options

pwd

echo "=============1"
#mpirun $mpi_options -n $NPROCS --hostfile hostfile.txt --bind-to numa ./hello_mpi
mpirun $mpi_options -n $SLURM_NTASKS --hostfile hostfile.txt --bind-to numa /data/hello-world/hello_mpi
echo "=============2"
mpirun $mpi_options -n $SLURM_NTASKS --hostfile hostfile.txt --bind-to numa ./wrf.exe
echo "=============3"
