#!/bin/bash

. ~/spack/share/spack/setup-env.sh
source /etc/profile.d/modules.sh
module use /usr/share/Modules/modulefiles

spack install dune
spack install opm-simulators

