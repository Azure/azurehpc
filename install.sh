#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -d "$DIR/bin" ]; then
    mkdir $DIR/bin
fi
pushd $DIR/bin >/dev/null
for fullpath in $DIR/libexec/azhpc-*.sh; do
    fname=${fullpath##*/}
    pyname=$(dirname $fullpath)/py$fname
    if [ ! -L "${fname%%.sh}" ]; then
        if [ -e $pyname ]; then
            ln -s $pyname ${fname%%.sh}
        else
            ln -s $fullpath ${fname%%.sh}
        fi
    fi
done
popd >/dev/null

export PATH=${DIR}/bin:$PATH
export azhpc_dir=$DIR

