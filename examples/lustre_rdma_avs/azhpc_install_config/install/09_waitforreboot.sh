#!/bin/bash

# expecting to be in $tmp_dir
cd "$( dirname "${BASH_SOURCE[0]}" )/.."

scripts/waitforreboot.sh >> install/09_waitforreboot.log 2>&1

