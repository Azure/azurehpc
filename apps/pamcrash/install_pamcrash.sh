#!/bin/bash

install_dir=/apps

#NOTE!!: Update the path to the pamcrash install files before running the script
inst1=/path/to/VPSolution-2017.0.2_Solvers_Linux-Intel64.tar.bz2 
inst2=/path/to/VPSolution-2018.01_DMP+SMP-Solvers_Linux-Intel64.tar.bz2
inst3=/path/to/mpm_master.171124.3-linux-x64-intel.tar.gz

tmp_dir=/tmp/tmp-pamcrash

mkdir $tmp_dir
pushd $tmp_dir

echo "Install pamcrash"
echo "Installer 1: $inst1"
echo "Installer 2: $inst2"
echo "Installer 3: $inst3"

tar -xvf ${inst1} -C $install_dir

tar -xvf ${inst2} -C $install_dir

tar -xvf ${inst3} -C $install_dir/pamcrash_safe/2018.01/Linux_x86_64/lib/

popd
rm -rf $tmp_dir
