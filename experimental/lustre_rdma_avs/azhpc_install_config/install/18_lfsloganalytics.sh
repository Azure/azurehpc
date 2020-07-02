#!/bin/bash

# expecting to be in $tmp_dir
cd "$( dirname "${BASH_SOURCE[0]}" )/.."

tag=${1:-lfsloganalytics}

if [ ! -f "hostlists/tags/$tag" ]; then
    echo "    Tag is not assigned to any resource (not running)"
    exit 0
fi

if [ "$(wc -l < hostlists/tags/$tag)" = "0" ]; then
    echo "    Tag does not contain any resources (not running)"
    exit 0
fi

pssh -p 50 -t 0 -i -h hostlists/tags/$tag "cd azhpc_install_config; sudo scripts/lfsloganalytics.sh 'lfs' 'eb2e4150-e0fa-494d-8f60-291e27820eff' '0iKHSuo3C36gwxYYZSBIIVB8g5l7A1qztuF77oVwZlFV9iKqke/Jajc+qVLkt1SB7LNimpeb3Q++qerMtnZvuw=='" >> install/18_lfsloganalytics.log 2>&1
