#!/bin/bash
export azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

$azhpc_pypath $azhpc_dir/pyazhpc/azhpc.py scp $*

