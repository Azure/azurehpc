#!/bin/bash

install_dir=/apps

inst=$(readlink -f $1)

tmp_dir=/tmp/tmp-fluent

mkdir $tmp_dir
pushd $tmp_dir

echo "Install Fluent"
echo "Installer: $1"

tar xf $inst

yum groupinstall -y "X Window System"
yum -y install freetype motif.x86_64 mesa-libGLU-9.0.0-4.el7.x86_64

./INSTALL -silent -install_dir $install_dir -fluent -nohelp -disablerss

popd
rm -rf $tmp_dir
