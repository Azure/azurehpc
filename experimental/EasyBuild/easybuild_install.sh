#!/bin/bash
set -euo pipefail

STACK_DIR=${1:-/apps}
EB_DIR=${STACK_DIR}/EasyBuild

# Ensure Lmod is loaded in the environment
# This is necessary for the EasyBuild bootstrap to generate Lua module instead of Tcl
if [ -f /etc/profile.d/z00_lmod.sh ]; then
    source /etc/profile.d/z00_lmod.sh
else
    printf '\nERROR: Cannot find Lmod initialization file!\n'
    printf '       Check that Lmod is installed in the system.\n\n'
    exit 2
fi

# Create stack directory
if [ ! -d $STACK_DIR ]; then
    sudo mkdir -pv $STACK_DIR
    sudo chmod -v 777 $STACK_DIR
fi

# EasyBuild configuration
EB_CONFIGDIR=${EB_DIR}/easybuild.d
if [ ! -d $EB_CONFIGDIR ]; then
    mkdir -pv $EB_CONFIGDIR
fi

cat << EOF > ${EB_CONFIGDIR}/easybuild.cfg
[config]
buildpath = /tmp
prefix = ${EB_DIR}
module-depends-on = true
module-naming-scheme = HierarchicalMNS
module-syntax = Lua
modules-tool = Lmod
[override]
allow-loaded-modules = EasyBuild
detect-loaded-modules = purge
minimal-toolchains = true
trace = true
use-existing-modules = true
zip-logs = gzip
rpath = true
EOF

# Use EasyBuild configuration for bootstrap
export XDG_CONFIG_DIRS=${EB_DIR}

# Install EasyBuild
sudo yum install -y python3
wget https://raw.githubusercontent.com/easybuilders/easybuild-framework/develop/easybuild/scripts/bootstrap_eb.py
python3 bootstrap_eb.py ${EB_DIR}
rm -f bootstrap_eb.py

# Set the custom EasyBuild configuration file path when its module is loaded
echo "setenv(\"XDG_CONFIG_DIRS\", \"${EB_DIR}\")" >> ${EB_DIR}/modules/all/Core/EasyBuild/*.lua

# Enforce source archives checksum check when building software
# It cannot be added before since the bootstrap would fail
echo 'enforce-checksums = true' >> ${EB_CONFIGDIR}/easybuild.cfg

# Install required OS dependencies
sudo yum install -y openssl-devel
sudo yum install -y python36-pyOpenSSL
sudo pip3 install requests
