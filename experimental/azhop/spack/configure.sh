#!/bin/bash
. ~/spack/share/spack/setup-env.sh

echo "Add GCC compiler"
spack compiler find /opt/gcc-9.2.0/

echo "Configure external MPI packages"
cat <<EOF >~/.spack/packages.yaml
packages:
  all:
    target: [x86_64]
    providers: 
      mpi: [hpcx]
  openmpi:
    externals:
    - spec: openmpi@4.0.5%gcc@9.2.0
      modules:
      - mpi/openmpi-4.0.5
    buildable: False
  hpcx:
    externals:
    - spec: hpcx@2.7.4%gcc@9.2.0
      modules:
      - mpi/hpcx-v2.7.4
    buildable: False
EOF

