#!/bin/bash
export azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

PYTHONPATH=$PYTHONPATH:$AZHPC_PYTHONPATH $azhpc_pypath $azhpc_dir/pyazhpc/azhpc.py destroy $*

