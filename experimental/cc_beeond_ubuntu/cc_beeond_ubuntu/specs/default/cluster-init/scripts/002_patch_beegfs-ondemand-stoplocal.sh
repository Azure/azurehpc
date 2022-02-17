#!/bin/bash

cd /opt/beegfs/lib
patch -t -p0 < $CYCLECLOUD_SPEC_PATH/files/beegfs-ondemand-stoplocal.patch
