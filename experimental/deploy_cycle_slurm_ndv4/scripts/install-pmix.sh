#!/bin/bash

cd ~/
mkdir -p /opt/pmix/v3
apt install -y libevent-dev
tar xvf $CYCLECLOUD_SPEC_PATH/files/openpmix-3.1.6.tar.gz
cd openpmix-3.1.6
#mkdir -p pmix/build/v3 pmix/install/v3
#cd pmix
#git clone https://github.com/openpmix/openpmix.git source
#cd source/
#git branch -a
#git checkout v3.1
#git pull
./autogen.sh
#cd ../build/v3/
./configure --prefix=/opt/pmix/v3
make -j install >/dev/null
