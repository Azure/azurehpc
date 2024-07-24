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

#EST1  => select=(1-4); nodearray=execute1; ncpus=120; mpiprocs=120
#EST2  => select=(1-4); nodearray=execute2; ncpus=96; mpiprocs=96
#EST3  => select=(1-4); nodearray=execute3; ncpus=64; mpiprocs=64

sbatch --export="ALL,SKU_TYPE=hbv3,WRKDAY=$data" $path_scr/run_wps1_openmpi.slurm

JOB_wps1=$(sbatch --parsable --export="SKU_TYPE=hbv3,WRKDAY=$data" $path_scr/run_wps1_openmpi.slurm)
JOB_wps2=$(sbatch --parsable --dependency=afterany:$JOB_wps1 --export="SKU_TYPE=hbv3,WRKDAY=$data" $path_scr/run_wps2_openmpi.slurm)
JOB_wrf1=$(sbatch --parsable --dependency=afterany:$JOB_wps2 --export="SKU_TYPE=hbv3,WRKDAY=$data" $path_scr/run_wrf1_openmpi.slurm)
JOB_wrf2=$(sbatch --parsable --dependency=afterany:$JOB_wrf1 --export="SKU_TYPE=hbv3,WRKDAY=$data" $path_scr/run_wrf2_openmpi.slurm)

#JOB_wps1=$(qsub -N wps1 -l select=1:nodearray=execute2:ncpus=16:mpiprocs=16,place=scatter:excl -v "SKU_TYPE=hbv2,WRKDAY=$data" $path_scr/run_wps1_openmpi.pbs)
#JOB_wps2=$(qsub -W depend=afterany:$JOB_wps1 -N wps2 -l select=1:nodearray=execute2:ncpus=16:mpiprocs=16,place=scatter:excl -v "SKU_TYPE=hbv2,WRKDAY=$data" $path_scr/run_wps2_openmpi.pbs)
#JOB_wrf1=$(qsub -W depend=afterany:$JOB_wps2 -N wrf1 -l select=1:nodearray=execute2:ncpus=64:mpiprocs=64,place=scatter:excl -v "SKU_TYPE=hbv2,WRKDAY=$data" $path_scr/run_wrf1_openmpi.pbs)
#JOB_wrf2=$(qsub -W depend=afterany:$JOB_wrf1 -N wrf2 -l select=4:nodearray=execute2:ncpus=96:mpiprocs=96,place=scatter:excl -v "SKU_TYPE=hbv2,WRKDAY=$data" $path_scr/run_wrf2_openmpi.pbs)

exit
