#!/bin/bash
#SBATCH --job-name=wrf2
#SBATCH --partition=hpc
#SBATCH --ntasks-per-node=96
#SBATCH --nodes=4
#SBATCH --exclusive
#SBATCH --output=slurm-wrf2-%j.out

# Capture start time
start_time=$(date +%s)

SKU_TYPE=${1:-$SKU_TYPE}
SKU_TYPE=${SKU_TYPE:-"hbv3"}

WRFDAT="/data/wrfdata"
WPSDIR=${WRFDAT}/wpsdir
WRFDIR=${WRFDAT}/wrfdir
WRKDAY=${2:-$WRKDAY}

ANO=`echo ${WRKDAY} | cut -c 1-4`
MES=`echo ${WRKDAY} | cut -c 5-6`
DIA=`echo ${WRKDAY} | cut -c 7-8`

echo $WRFDAT $WPSDIR $WRFDIR

mkdir -p $WRFDIR/$WRKDAY

echo "SKU_TYPE:" $SKU_TYPE

# Load environment variables
echo "Load environment variables"
source /data/azurehpc/apps/wrf/env-variables $SKU_TYPE

cd $WRFDIR/$WRKDAY
echo "cd $WRFDIR/$WRKDAY"

mpi_options="-x LD_LIBRARY_PATH "
if [ -n $LD_PRELOAD ]; then
    mpi_options+="-x LD_PRELOAD"
fi
echo "mpi_options:" $mpi_options

echo "SLURM_JOB_NODELIST:" $SLURM_JOB_NODELIST
echo "SLURM_NTASKS:" $SLURM_NTASKS

scontrol show hostname $SLURM_JOB_NODELIST > hostfile.txt

mpirun $mpi_options -n $SLURM_NTASKS --hostfile hostfile.txt --bind-to numa wrf.exe

# Capture end time
end_time=$(date +%s)
# Calculate duration
duration=$((end_time - start_time))
# Format duration to hh:mm:ss
hours=$(printf "%02d" $((duration / 3600)))
minutes=$(printf "%02d" $(( (duration % 3600) / 60 )))
seconds=$(printf "%02d" $((duration % 60)))
duration="${hours}:${minutes}:${seconds}"

echo "WRF2 finished."
echo "Execution time: $duration seconds"