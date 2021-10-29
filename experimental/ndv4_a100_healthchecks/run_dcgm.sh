#!/bin/bash

# Expect all tests to pass

#RUN_LEVEL can be 1, 2 or 3 (1 quick tests, 3 all/comprehensive tests)
RUN_LEVEL=3
DCGM_EXE=/usr/bin/dcgmi
OUT_DIR=~/healthchecks/dcgm/out
HOSTNAME=`hostname`


$DCGM_EXE diag -r $RUN_LEVEL >& ${OUT_DIR}/${HOSTNAME}_dcgmi_r_${RUN_LEVEL}.out
