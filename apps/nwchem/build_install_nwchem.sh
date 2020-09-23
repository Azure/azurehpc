#!/bin/bash
#
APP_NAME=nwchem
APP_VERSION=7.0.0
SHARED_APP=${APP_INSTALL_DIR:-/apps}
SKU_TYPE=${SKU_TYPE:-hbv2}
MODULE_DIR=${SHARED_APP}/modulefiles/${SKU_TYPE}
MODULE_NAME=${APP_NAME}_${APP_VERSION}
INSTALL_DIR=${SHARED_APP}/${SKU_TYPE}/${APP_NAME}
SHARED_DATA=${DATA_DIR:-/data}
DATA_DIR=${SHARED_DATA}/${APP_NAME}
DATA_NAME=h2o_freq.nw
PARALLEL_BUILD=16
#

function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module
prepend-path PATH ${INSTALL_DIR}/bin
prepend-path LD_LIBRARY_PATH ${INSTALL_DIR}/lib
setenv       NWCHEMROOT   ${INSTALL_DIR}
EOF
}


install_nwchem_data() {
mkdir -p ${DATA_DIR}
cat << EOF >> ${DATA_DIR}/${DATA_NAME}
start h2o_freq
charge 1
geometry units angstroms
 O       0.0  0.0  0.0
 H       0.0  0.0  1.0
 H       0.0  1.0  0.0
end
basis
 H library sto-3g
 O library sto-3g
end
scf
 uhf; doublet
 print low
end
title "H2O+ : STO-3G UHF geometry optimization"
task scf optimize
basis
 H library 6-31g**
 O library 6-31g**
end
title "H2O+ : 6-31g** UMP2 geometry optimization"
task mp2 optimize
mp2; print none; end
scf; print none; end
title "H2O+ : 6-31g** UMP2 frequencies"
task mp2 freq
EOF
}

#
export NWCHEM_TOP=${INSTALL_DIR}/${APP_NAME}-${APP_VERSION}-release
export NWCHEM_TARGET=LINUX64
export USE_MPI=y
export USE_MPIF=y
export USE_MPIF4=y
export USE_NOIO=TRUE
export LIB_DEFINES="_DDFLT_TOT_MEM=10000000000"
export USE_PYTHONCONFIG=y
export PYTHONHOME=/usr
export PYTHONVERSION=2.7
export USE_INTERNALBLAS=n
export USE_64TO32=y
export BLAS_SIZE=4
#
mkdir -p ${INSTALL_DIR}
pushd ${INSTALL_DIR}
wget "https://github.com/nwchemgit/nwchem/archive/v${APP_VERSION}-release.tar.gz" -O - | tar xvz
#
#export MODULEPATH=/opt/hpcx-v2.4.1-gcc-MLNX_OFED_LINUX-4.6-1.0.1.1-redhat7.6-x86_64/modulefiles:$MODULEFILE

spack install openblas%gcc@9.2.0 target=zen2
source ${SPACK_ROOT}/share/spack/setup-env.sh
OPENBLAS_DIR=$(spack location -i openblas)
export BLASOPT="-L${OPENBLAS_DIR}/lib -lopenblas"
export LAPACK_LIB=$BLASOPT

module load mpi/openmpi
#
cd $NWCHEM_TOP/src
make clean
echo "start make nwchecm_config, `date`"
make -j ${PARALLEL_BUILD} nwchem_config NWCHEM_MODULES="all python"
echo "end make nwchem_config, `date`"
#
echo "start make 64_to_32, `date`"
make -j ${PARALLEL_BUILD} 64_to_32 FC=gfortran
echo "end make 64_to_32, `date`"
echo "start make, `date`"
make -j ${PARALLEL_BUILD} FC=gfortran
echo "end make, `date`"
#
mkdir $INSTALL_DIR/bin
mkdir $INSTALL_DIR/data
#
cp $NWCHEM_TOP/bin/${NWCHEM_TARGET}/* $INSTALL_DIR/bin
cd $INSTALL_DIR/bin
chmod 755 nwchem
#
cd $NWCHEM_TOP/src/basis
cp -r libraries $INSTALL_DIR/data
cd $NWCHEM_TOP/src/
cp -r data $INSTALL_DIR
cd $NWCHEM_TOP/src/nwpw
cp -r libraryps $INSTALL_DIR/data
#
DEFAULTNWCHEMRC=default.nwchemrc
echo "nwchem_basis_library $INSTALL_DIR/data/libraries/" > $INSTALL_DIR/data/$DEFAULTNWCHEMRC
echo "nwchem_nwpw_library $INSTALL_DIR/data/libraryps/" >> $INSTALL_DIR/data/$DEFAULTNWCHEMRC
echo "ffield amber" >> $INSTALL_DIR/data/$DEFAULTNWCHEMRC
echo "amber_1 $INSTALL_DIR/data/amber_s/" >> $INSTALL_DIR/data/$DEFAULTNWCHEMRC
echo "amber_2 $INSTALL_DIR/data/amber_q/" >> $INSTALL_DIR/data/$DEFAULTNWCHEMRC
echo "amber_3 $INSTALL_DIR/data/amber_x/" >> $INSTALL_DIR/data/$DEFAULTNWCHEMRC
echo "amber_4 $INSTALL_DIR/data/amber_u/" >> $INSTALL_DIR/data/$DEFAULTNWCHEMRC
echo "spce    $INSTALL_DIR/data/solvents/spce.rst" >> $INSTALL_DIR/data/$DEFAULTNWCHEMRC
echo "charmm_s $INSTALL_DIR/data/charmm_s/" >> $INSTALL_DIR/data/$DEFAULTNWCHEMRC
echo "charmm_x $INSTALL_DIR/data/charmm_x/" >> $INSTALL_DIR/data/$DEFAULTNWCHEMRC
#
create_modulefile
install_nwchem_data
