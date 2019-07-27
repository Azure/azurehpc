#!/bin/bash
#
# This script requires a single parameter
# first paramater : Full path to output directory containing the resulting STREAM benchmark results.

OUTPUT_DIR=$1
#
cd $OUTPUT_DIR
grep  Triad */* | sort -n -k 2 2>&1 | tee stream_report.log_$$
