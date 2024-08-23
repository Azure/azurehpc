#!/bin/bash
#SBATCH --job-name=wps2
#SBATCH --partition=hpc
#SBATCH --ntasks-per-node=16
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --output=slurm-wps2-%j.out

# Capture start time
start_time=$(date +%s)

SKU_TYPE=${1:-$SKU_TYPE}
SKU_TYPE=${SKU_TYPE:-"hbv3"}

path_scr=/apps/scripts
WRFDAT="/data/wrfdata"
WPSDIR=${WRFDAT}/wpsdir
WRFDIR=${WRFDAT}/wrfdir
WRKDAY=${2:-$WRKDAY}
echo "WRKDAY:" $WRKDAY

ANO=`echo ${WRKDAY} | cut -c 1-4`
MES=`echo ${WRKDAY} | cut -c 5-6`
DIA=`echo ${WRKDAY} | cut -c 7-8`
HOR=`echo ${WRKDAY} | cut -c 9-10`

#DIAFIM=`date +%Y%m%d --date="$ANO$MES$DIA +5 day"`
DIAFIM=`echo ${WRKDAY} 132 | awk -f $path_scr/fwddatan.awk`

ANOF=`echo ${DIAFIM} | cut -c 1-4`
MESF=`echo ${DIAFIM} | cut -c 5-6`
DIAF=`echo ${DIAFIM} | cut -c 7-8`
HORF=`echo ${DIAFIM} | cut -c 9-10`

echo $WRFDAT $WPSDIR $WRFDIR $WRKDAY $DIAFIM

mkdir -p $WPSDIR/$WRKDAY

echo "SKU_TYPE:" $SKU_TYPE

SHARED_APP=${SHARED_APP:-/apps}

# Load environment variables
echo "Load environment variables"
source /data/azurehpc/apps/wrf/env-variables $SKU_TYPE

echo "SLURM_SUBMIT_DIR:" $SLURM_SUBMIT_DIR

cd ${WPSDIR}/${WRKDAY}
echo "cd $WPSDIR/$WRKDAY"

echo "Running link_grib.csh..." 
./link_grib.csh ${WRFDAT}/gfs_data/${WRKDAY}/gfs*

echo "Running ungrib.exe..." 
./ungrib.exe >& ungrib.log

# Capture end time
end_time=$(date +%s)
# Calculate duration
duration=$((end_time - start_time))
# Format duration to hh:mm:ss
hours=$(printf "%02d" $((duration / 3600)))
minutes=$(printf "%02d" $(( (duration % 3600) / 60 )))
seconds=$(printf "%02d" $((duration % 60)))
duration="${hours}:${minutes}:${seconds}"

echo "WPS2 finished."
echo "Execution time: $duration seconds"