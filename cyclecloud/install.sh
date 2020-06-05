#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Uploading azhpc project for cycle"
pushd $DIR/azhpc
cyclecloud project upload
popd

for f in templates/*.txt; do 
    cyclecloud delete_template $f
    cyclecloud import_template -f templates/$f.txt --force
done

