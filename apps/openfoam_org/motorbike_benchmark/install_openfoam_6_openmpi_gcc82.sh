#!/bin/bash

source /etc/profile # so we can load modules
HPCX_DIR=$(ls -atr /opt | grep hpcx | tail -n1)
module use /opt/${HPCX_DIR}/modulefiles
module load hpcx
module load gcc-8.2.0

BUILD_DIR=/scratch
INSTALL_DIR=/apps

# openfoam will get confused if the BUILD_DIR is a symlink
cd $(readlink -f $BUILD_DIR)
mkdir OpenFOAM
cd OpenFOAM
git clone git://github.com/OpenFOAM/OpenFOAM-6.git
git clone git://github.com/OpenFOAM/ThirdParty-6.git

cat <<EOF >setenv.sh
MY_DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
source /etc/profile # so we can load modules
HPCX_DIR=\$(ls -atr /opt | grep hpcx | tail -n1)
module use /opt/\${HPCX_DIR}/modulefiles
module load hpcx
module load gcc-8.2.0
. \$MY_DIR/OpenFOAM-6/etc/bashrc

EOF

source setenv.sh
cd OpenFOAM-6
./Allwmake -j 2>&1 | tee build.log

cp -r ${BUILD_DIR}/OpenFOAM ${INSTALL_DIR}/

