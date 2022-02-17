#!/bin/bash

cd /opt/beegfs/sbin
patch -t -p0 < $CYCLECLOUD_SPEC_PATH/files/beeond.patch
