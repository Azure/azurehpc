#!/bin/bash

. ~/spack/share/spack/setup-env.sh
source /etc/profile.d/modules.sh
module use /usr/share/Modules/modulefiles

spack install hdf5+fortran+hl ^openmpi
spack install netcdf-fortran ^hdf5+fortran+hl ^openmpi
spack install wrf ^netcdf-fortran ^hdf5+fortran+hl ^openmpi

spack install wps build_type=dmpar ^netcdf-fortran ^openmpi

