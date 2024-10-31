#!/bin/bash

PYXIS_VER=0.20.0
TMP_DIR=/tmp
SHARED_DIR=/sched/pyxis

source $CYCLECLOUD_SPEC_PATH/files/common_functions.sh

function install_build_deps() {
   apt-get -y install gcc make
}

function install_from_source() {
   install_build_deps
   cd ${TMP_DIR}
   tar -xzf $CYCLECLOUD_SPEC_PATH/files/pyxis_${PYXIS_VER}.tar.gz
   cd pyxis-${PYXIS_VER}
   make install

   # Copy pyxis library to cluster shared directory
   mkdir -p ${SHARED_DIR}
   cp -fv /usr/local/lib/slurm/spank_pyxis.so ${SHARED_DIR}

   # Make sure /usr/lib64/slurm directory exists
   mkdir -p /usr/lib64/slurm

   # Install Pyxis Slurm plugin
   cp -fv /usr/local/lib/slurm/spank_pyxis.so /usr/lib64/slurm
   chmod +x /usr/lib64/slurm/spank_pyxis.so

   cd ~
   rm -rf ${TMP_DIR}/pyxis-${PYXIS_VER}
}

function install_compute_node() {
   mkdir -p /usr/lib64/slurm
   cp -v /sched/pyxis/spank_pyxis.so /usr/lib64/slurm
   chmod +x /usr/lib64/slurm/spank_pyxis.so
}

# Ensure there are no broken dependencies
NEEDRESTART_MODE=a apt-get --yes --fix-broken install

if is_slurm_controller; then
   install_from_source
else
   install_compute_node
fi

