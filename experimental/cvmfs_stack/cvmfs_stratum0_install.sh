#!/bin/bash
set -euo pipefail

sudo yum install -y bzip2 libuuid-devel gcc gcc-c++ valgrind-devel cmake \
                    fuse fuse-devel fuse3 fuse3-libs fuse3-devel libattr-devel \
                    openssl-devel patch pkgconfig unzip python-devel libcap-devel \
                    unzip git

git clone https://github.com/hmeiland/cvmfs.git
pushd cvmfs > /dev/null
git checkout import_s3
mkdir build
pushd build > /dev/null
cmake ..
make
sudo make install
sudo cvmfs_server fix-permissions
popd > /dev/null
popd > /dev/null
rm -rf cvmfs
