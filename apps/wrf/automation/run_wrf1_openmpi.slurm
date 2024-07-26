#!/bin/bash
#SBATCH --job-name=wrf1
#SBATCH --partition=hpc
#SBATCH --ntasks-per-node=64
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --output=slurm-wrf1-%j.out

# Capture start time
start_time=$(date +%s)

SKU_TYPE=${1:-$SKU_TYPE}
SKU_TYPE=${SKU_TYPE:-"hbv3"}

path_scr=/apps/scripts
WRFDAT="/data/wrfdata"
WPSDIR=${WRFDAT}/wpsdir
WRFDIR=${WRFDAT}/wrfdir
WRKDAY=${2:-$WRKDAY}

ANO=`echo ${WRKDAY} | cut -c 1-4`
MES=`echo ${WRKDAY} | cut -c 5-6`
DIA=`echo ${WRKDAY} | cut -c 7-8`
HOR=`echo ${WRKDAY} | cut -c 9-10`

#DIAFIM=`date +%Y%m%d --date="$ANO$MES$DIA +5 day"`
DIAFIM=`echo ${WRKDAY} 132 | awk -f $path_scr/fwddatan.awk`

ANOf=`echo ${DIAFIM} | cut -c 1-4`
MESf=`echo ${DIAFIM} | cut -c 5-6`
DIAf=`echo ${DIAFIM} | cut -c 7-8`
HORF=`echo ${DIAFIM} | cut -c 9-10`

echo $WRFDAT $WPSDIR $WRFDIR

mkdir -p $WRFDIR/$WRKDAY

# Load environment variables
echo "Load environment variables"
source /data/azurehpc/apps/wrf/env-variables $SKU_TYPE

cd $WRFDIR/$WRKDAY
echo "cd $WRFDIR/$WRKDAY"

echo "ln -s ${WPSDIR}/${WRKDAY}/met_em* ."
ln -s ${WPSDIR}/${WRKDAY}/met_em* $WRFDIR/$WRKDAY

echo "ln -s ${WRFDAT}/tables/wrf/* ."
ln -s ${WRFDAT}/tables/wrf/* $WRFDIR/$WRKDAY

echo "Copying namelist.input"
cp ${WRFDAT}/tables/namelist/namelist.input $WRFDIR/$WRKDAY

sed -i s/aai/${ANO}/g namelist.input
sed -i s/mmi/${MES}/g namelist.input
sed -i s/ddi/${DIA}/g namelist.input
sed -i s/hhi/${HOR}/g namelist.input

sed -i s/aaf/${ANOf}/g namelist.input
sed -i s/mmf/${MESf}/g namelist.input
sed -i s/ddf/${DIAf}/g namelist.input
sed -i s/hhf/${HORF}/g namelist.input

mpi_options="-x LD_LIBRARY_PATH "
if [ -n $LD_PRELOAD ]; then
    mpi_options+="-x LD_PRELOAD"
fi
echo "mpi_options:" $mpi_options

echo "SLURM_JOB_NODELIST:" $SLURM_JOB_NODELIST
echo "SLURM_NTASKS:" $SLURM_NTASKS

scontrol show hostname $SLURM_JOB_NODELIST > hostfile.txt

echo "Running real.exe..."
mpirun $mpi_options -n $SLURM_NTASKS --hostfile hostfile.txt --bind-to numa real.exe

# Capture end time
end_time=$(date +%s)
# Calculate duration
duration=$((end_time - start_time))
# Format duration to hh:mm:ss
hours=$(printf "%02d" $((duration / 3600)))
minutes=$(printf "%02d" $(( (duration % 3600) / 60 )))
seconds=$(printf "%02d" $((duration % 60)))
duration="${hours}:${minutes}:${seconds}"

echo "WRF1 finished."
echo "Execution time: $duration seconds"