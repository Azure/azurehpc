#!/bin/bash

. ~/spack/share/spack/setup-env.sh
module use /usr/share/Modules/modulefiles

spack install boost +system+test+date_time

spack install dune
spack install opm-simulators
