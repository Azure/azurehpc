#!/bin/bash

. ~/spack/share/spack/setup-env.sh
module use /usr/share/Modules/modulefiles

sudo yum install -y freeglut-devel
spack install boost +system+test+date_time

spack install dune
spack install opm-simulators
