#!/bin/bash
#PBS -N OPM
#PBS -l select=1:ncpus=40:mpiprocs=40:slot_type=hc44rs
#PBS -k oed
#PBS -j oe
#PBS -l walltime=3600

INPUT=~/opm-data/norne/NORNE_ATW2013.DATA
INPUT_DIR=${INPUT%/*}
INPUT_FILE=${INPUT##*/}
NUM_THREADS=1

. ~/spack/share/spack/setup-env.sh
module use /usr/share/Modules/modulefiles
spack load opm-simulators

pushd $INPUT_DIR
CORES=`cat $PBS_NODEFILE | wc -l`

mpirun  -np $CORES \
        -hostfile $PBS_NODEFILE \
        --map-by numa:PE=$NUM_THREADS \
        --bind-to core \
        --report-bindings \
        --display-allocation \
        -x LD_LIBRARY_PATH \
        -x PATH \
        -wd $PWD \
        flow --ecl-deck-file-name=$INPUT_FILE \
             --output-dir=$INPUT_DIR/out_parallel \
             --output-mode=none \
             --output-interval=10000 \
             --threads-per-process=$NUM_THREADS
popd