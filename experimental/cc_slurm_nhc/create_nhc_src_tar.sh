#!/bin/bash

TODAY=$(date +"%m-%d-%Y")
TAR_FILE=lbnl-nhc-${TODAY}.tar
CWD=`pwd`

cd /tmp
git clone https://github.com/mej/nhc.git
tar -cvf ${CWD}/$TAR_FILE nhc
gzip ${CWD}/$TAR_FILE
rm -rf /tmp/nhc

