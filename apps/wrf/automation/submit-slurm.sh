#!/bin/sh
# JOB_wps1 => Executa o download, altera a namelist.wps e executa o ungrib.exe
# JOB_wps2 => Exuta o geogrid.exe e o metgrid.exe
# JOB_wrf1 => Altera a namelist.input e executa o real.exe
# JOB_wrf2 => Executa o wrf.exe
# FILAS    =>  execute1 com 120 ncpus; execute2 com 96 ncpus (otimizada); execute3 com 64 ncpus (otimizada)
# NODES    => select 1,2,3 e 4 (maximo de 4 nodes)
# MPIPROCS sempre igual a NCPUS

path_wrf=/data/wrfdata/wrfdir
path_wps=/data/wrfdata/wpsdir
path_scr=/apps/scripts

data=$1
echo "data: $data"
mkdir -p $path_wps/$data
mkdir -p $path_wrf/$data

#sbatch --export="ALL,SKU_TYPE=hbv3,WRKDAY=$data" $path_scr/run_wps2_openmpi.slurm

# ncpus=16 
JOB_wps1=$(sbatch --parsable --export="ALL,SKU_TYPE=hbv3,WRKDAY=$data" $path_scr/run_wps1_openmpi.slurm)
# ncpus=16 
JOB_wps2=$(sbatch --parsable --dependency=afterany:$JOB_wps1 --export="ALL,SKU_TYPE=hbv3,WRKDAY=$data" $path_scr/run_wps2_openmpi.slurm)
# ncpus=64
JOB_wrf1=$(sbatch --parsable --dependency=afterany:$JOB_wps2 --export="ALL,SKU_TYPE=hbv3,WRKDAY=$data" $path_scr/run_wrf1_openmpi.slurm)
# ncpus=96
JOB_wrf2=$(sbatch --parsable --dependency=afterany:$JOB_wrf1 --export="ALL,SKU_TYPE=hbv3,WRKDAY=$data" $path_scr/run_wrf2_openmpi.slurm)

exit
