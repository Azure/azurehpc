#!/bin/bash
export azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

/opt/az/bin/python3 $azhpc_dir/pyazhpc/azhpc.py status $*

