#!/bin/bash

export NCARG_ROOT=~/ncl
export PATH=$NCARG_ROOT/bin:$PATH

source env_wrf.sh hc

pushd wrf
ncl $WPSROOT/util/plotgrids_new.ncl
popd