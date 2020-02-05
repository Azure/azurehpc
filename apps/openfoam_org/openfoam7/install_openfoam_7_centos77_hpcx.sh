#!/bin/bash

cd $HOME
mkdir OpenFOAM
cd OpenFOAM
git clone git://github.com/OpenFOAM/OpenFOAM-7.git
git clone git://github.com/OpenFOAM/ThirdParty-7.git

cat <<EOF >setenv.sh
source /etc/profile
MY_DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
module load gcc-9.2.0
module load mpi/hpcx-v2.5.0
. \$MY_DIR/OpenFOAM-7/etc/bashrc
EOF

source setenv.sh
cd OpenFOAM-7
ncores=$(cat /proc/cpuinfo | grep ^processor | wc -l)
./Allwmake -j $ncores 2>&1 | tee build.log
