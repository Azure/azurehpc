#!/bin/bash

. ~/spack/share/spack/setup-env.sh
source /etc/profile.d/modules.sh
module use /usr/share/Modules/modulefiles

git clone https://gitlab.dune-project.org/spack/dune-spack.git

spack repo add dune-spack

