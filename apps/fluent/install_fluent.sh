#!/bin/bash

install_dir=/apps

#NOTE!!: Update the path to the fluent install file before running the script
inst=/path/to/fluent_install_file.tar

tmp_dir=/tmp/tmp-fluent

mkdir $tmp_dir
pushd $tmp_dir

echo "Install Fluent"
echo "Installer: $inst"

tar xf $inst

yum groupinstall -y "X Window System"
yum -y install freetype motif.x86_64 mesa-libGLU-9.0.0-4.el7.x86_64

./INSTALL -silent -install_dir $install_dir -fluent -nohelp -disablerss

popd
rm -rf $tmp_dir
