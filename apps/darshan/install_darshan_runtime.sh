#!/bin/bash
if [ "$NON_MPI" == 1 ]; then
   spack install darshan-runtime+pbs~mpi%gcc@9.2.0
else
   spack install darshan-runtime+pbs^openmpi@4.0.3%gcc@9.2.0
fi
