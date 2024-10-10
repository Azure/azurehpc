#!/bin/bash
sbatch --export=ALL,SKU_TYPE=hbv3,INPUTDIR=/apps/hbv3/wrf-openmpi/WRF-4.1.5/run /data/azurehpc/apps/wrf/run_wrf_openmpi.slurm
