#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Uploading azhpc project for cycle"
pushd $DIR/azhpc
cyclecloud upload project
popd

