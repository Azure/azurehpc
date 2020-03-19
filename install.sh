#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -d "$DIR/bin" ]; then
    mkdir $DIR/bin
fi
pushd $DIR/bin >/dev/null
# Create alias links for bash commands and override with python version if it exists
for fullpath in $DIR/libexec/azhpc-*.sh; do
    fname=${fullpath##*/}
    pyfullpath=$(dirname $fullpath)/py$fname
    if [ ! -L "${fname%%.sh}" ]; then
        if [ -e $pyfullpath ]; then
            ln -s $pyfullpath ${fname%%.sh}
        else
            ln -s $fullpath ${fname%%.sh}
        fi
    fi
done
# Create alias links for python version
for fullpath in $DIR/libexec/pyazhpc-*.sh; do
    fname=${fullpath##*/}
    fname=${fname#py}
    if [ ! -L "${fname%%.sh}" ]; then
        ln -s $fullpath ${fname%%.sh}
    fi
done

popd >/dev/null

export PATH=${DIR}/bin:$PATH
export azhpc_dir=$DIR
export azhpc_pypath=$(az --version | grep "Python location" | cut -d' ' -f3 | sed "s/'//g")
if [ -e /etc/centos-release ]; then
    export AZHPC_PYTHONPATH=/usr/lib64/az/lib/python3.6/site-packages
fi
