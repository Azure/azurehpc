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
      mpi: [openmpi]
  openmpi:
    externals:
    - spec: openmpi@4.1.0%gcc@9.2.0
      modules:
      - mpi/openmpi-4.1.0
    buildable: False
  hpcx:
    externals:
    - spec: hpcx@2.8.3%gcc@9.2.0
      modules:
      - mpi/hpcx-v2.8.3
    buildable: False
EOF

echo "Configure local settings"

cat <<EOF >~/.spack/config.yaml
config:
  build_stage:
    - /mnt/resource/$USER/spack-stage
    - ~/.spack/stage
EOF
