#!/bin/bash
#
OUTDIR=${OUTDIR:-/shared/data/osu_ring_bw_hpcx}
if [ ! -d $OUTDIR ]; then
   mkdir -p $OUTDIR
fi
cd $OUTDIR

module load mpi/hpcx

nodelist=$(scontrol show hostname $SLURM_JOB_NODELIST | paste -d, -s)

IFS=","
read -ra nodes <<< "$nodelist"
src=${nodes[0]}
dst=${nodes[1]}

mpirun -np 2 --host $src,$dst --map-by node -x LD_LIBRARY_PATH $HPCX_OSU_DIR/osu_latency | tee ${src}_to_${dst}_osu_latency.log
mpirun -np 2 --host $src,$dst --map-by node -x LD_LIBRARY_PATH $HPCX_OSU_DIR/osu_bw | tee ${src}_to_${dst}_osu_bw.log
mpirun -np 2 --host $src,$dst --map-by node -x LD_LIBRARY_PATH $HPCX_OSU_DIR/osu_bibw | tee ${src}_to_${dst}_osu_bibw.log
