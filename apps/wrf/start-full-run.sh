# Run WPS job
echo "Submiting WPS Job"
JOB_WPS=$(qsub -l select=1:nodearray=execute2:ncpus=120:mpiprocs=120,place=scatter:excl -v "SKU_TYPE=hbv2,INPUTDIR=/apps/hbv2/wps-openmpi/WPS-4.1/" /data/azurehpc/apps/wrf/run_wps_openmpi.pbs)
echo "WPS Job ID:$JOB_WPS"

# Run Real job
echo "Submiting Real Job"
JOB_Real=$(qsub -W depend=afterok:$JOB_WPS -l select=1:nodearray=execute2:ncpus=120:mpiprocs=120,place=scatter:excl -v "SKU_TYPE=hbv2,INPUTDIR=/apps/hbv2/wrf-openmpi/WRF-4.1.5/run/" /data/azurehpc/apps/wrf/run_real_openmpi.pbs)
echo "Real Job ID:$JOB_Real"

# Run WRF job
echo "Submiting WRF Job"
qsub -W depend=afterok:$JOB_Real -l select=1:nodearray=execute2:ncpus=120:mpiprocs=120,place=scatter:excl -v "SKU_TYPE=hbv2,INPUTDIR=/apps/hbv2/wrf-openmpi/WRF-4.1.5/run/" /data/azurehpc/apps/wrf/run_wrf_openmpi.pbs
