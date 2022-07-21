#!/bin/bash

PYXIS_VER=0.11.1
TMP_DIR=/tmp
SHARED_DIR=/sched/pyxis

source $CYCLECLOUD_SPEC_PATH/files/common_functions.sh

function install_build_deps() {
   apt-get -y install gcc make
}

function get_source() {
   wget https://github.com/NVIDIA/pyxis/archive/refs/tags/v${PYXIS_VER}.tar.gz
   tar xzf v${PYXIS_VER}.tar.gz
}

function install_from_source() {
   install_build_deps
   cd ${TMP_DIR}
   get_source
   cd pyxis-${PYXIS_VER}
   make install

   # Copy pyxis library to cluster shared directory
   mkdir -p ${SHARED_DIR}
   cp -fv /usr/local/lib/slurm/spank_pyxis.so ${SHARED_DIR}

   # Install Pyxis Slurm plugin
   cp -fv /usr/local/lib/slurm/spank_pyxis.so /usr/lib64/slurm
   chmod +x /usr/lib64/slurm/spank_pyxis.so

   cd ~
   rm -rf ${TMP_DIR}/v${PYXIS_VER}.tar.gz \
          ${TMP_DIR}/pyxis-${PYXIS_VER}
}

function install_compute_node() {
   cp -v /sched/pyxis/spank_pyxis.so /usr/lib64/slurm
   chmod +x /usr/lib64/slurm/spank_pyxis.so
}

if is_slurm_controller; then
   install_from_source
else
   install_compute_node
fi

