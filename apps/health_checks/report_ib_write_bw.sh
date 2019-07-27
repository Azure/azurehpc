#!/bin/bash
#
# This script requires a single parameter.
# first parameter : Full path to output directory containing the ib_write_bw results.
#
OUTPUT_DIR=$1
cd $OUTPUT_DIR
grep 65536 */* | sort -n -k 5 2>&1 | tee ib_write_bw_report.out_$$ 
