#!/bin/bash
#
APP_NAME=nwchem
APP_VERSION=6.8
SHARED_APP=/apps
MODULE_DIR=${SHARED_APP}/modulefiles
MODULE_NAME=${APP_NAME}_${APP_VERSION}
INSTALL_DIR=${SHARED_APP}/${APP_NAME}
SHARED_DATA=/data
DATA_DIR=${SHARED_DATA}/${APP_NAME}
DATA_NAME=h2o_freq.nw
PARALLEL_BUILD=16
#

function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module
prepend-path PATH ${INSTALL_DIR}/bin;
setenv LD_LIBRARY_PATH ${INSTALL_DIR}/lib;
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
export NWCHEM_TOP=${INSTALL_DIR}/${APP_NAME}-${APP_VERSION}
export NWCHEM_TARGET=LINUX64
#export ARMCI_NETWORK=MPI-MT
export USE_MPI=y
export USE_MPIF=y
export USE_MPIF4=y
export USE_NOIO=TRUE
export LIB_DEFINES="_DDFLT_TOT_MEM=10000000000"
export USE_PYTHONCONFIG=y
export PYTHONHOME=/usr
export PYTHONVERSION=2.7
export USE_INTERNALBLAS=y
#
mkdir -p ${SHARED_APP}/${APP_NAME}
pushd ${SHARED_APP}/${APP_NAME}
wget "https://github.com/nwchemgit/nwchem/releases/download/v6.8-release/nwchem-6.8-release.revision-v6.8-47-gdf6c956-srconly.2017-12-14.tar.bz2" -O - | tar xvj
#
export MODULEPATH=/opt/hpcx-v2.4.1-gcc-MLNX_OFED_LINUX-4.6-1.0.1.1-redhat7.6-x86_64/modulefiles:$MODULEFILE
module load gcc-8.2.0
module load hpcx
which mpif90
mpif90 -show
#
cd $NWCHEM_TOP/src
make clean
echo "start make nwchecm_config, `date`"
make -j ${PARALLEL_BUILD} nw_chem_config NWCHEM_MODULES="all python"
echo "end make nwchem_config, `date`"
#
echo "start make, `date`"
make -j ${PARALLEL_BUILD} FC=gfortran
echo "end make, `date`"
#
mkdir $INSTALL_DIR/bin
mkdir $INSTALL_DIR/data
#
cp $NWCHEM_TOP/bin/${NWCHEM_TARGET}/nwchem $INSTALL_DIR/bin
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
