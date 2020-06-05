#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


echo "Uploading azhpc project for cycle"
pushd $DIR/azhpc
cyclecloud project default_locker azure-storage
cyclecloud project upload
popd

for f in templates/*.txt; do
    template=${f##*/}
    template=${template%.txt}
    cyclecloud delete_template $template
    cyclecloud import_template -f $f --force
done

