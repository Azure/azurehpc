#!/bin/bash
#SBATCH --job-name=wps1
#SBATCH --partition=hpc
#SBATCH --ntasks-per-node=16
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --output=slurm-wps1-%j.out

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

# Waiting 30 seconds
echo "Waiting 30 seconds"
sleep 30s

# Download gfs data
echo "Downloading gfs data..."
python3 ${path_scr}/get_gfs_data.py $ANO $MES $DIA

echo "SLURM_SUBMIT_DIR:" $SLURM_SUBMIT_DIR

cd ${WPSDIR}/${WRKDAY}
echo "cd $WPSDIR/$WRKDAY"

echo "ln -s ${WRFDAT}/tables/wps/* $WPSDIR/$WRKDAY"	
ln -s ${WRFDAT}/tables/wps/* $WPSDIR/$WRKDAY

echo "Copying namelist.wps"
cp ${WRFDAT}/tables/namelist/namelist.wps $WPSDIR/$WRKDAY

sed -i s/wrkday/${WRKDAY}/g namelist.wps

sed -i s/aai/${ANO}/g namelist.wps
sed -i s/mmi/${MES}/g namelist.wps
sed -i s/ddi/${DIA}/g namelist.wps
sed -i s/hhi/${HOR}/g namelist.wps

sed -i s/aaf/${ANOF}/g namelist.wps
sed -i s/mmf/${MESF}/g namelist.wps
sed -i s/ddf/${DIAF}/g namelist.wps
sed -i s/hhf/${HORF}/g namelist.wps

# Capture end time
end_time=$(date +%s)
# Calculate duration
duration=$((end_time - start_time))
# Format duration to hh:mm:ss
hours=$(printf "%02d" $((duration / 3600)))
minutes=$(printf "%02d" $(( (duration % 3600) / 60 )))
seconds=$(printf "%02d" $((duration % 60)))
duration="${hours}:${minutes}:${seconds}"

echo "WPS1 finished."
echo "Execution time: $duration seconds"