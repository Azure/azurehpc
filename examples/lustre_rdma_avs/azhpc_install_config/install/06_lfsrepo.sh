#!/bin/bash

# expecting to be in $tmp_dir
cd "$( dirname "${BASH_SOURCE[0]}" )/.."

tag=${1:-lfsrepo}

if [ ! -f "hostlists/tags/$tag" ]; then
    echo "    Tag is not assigned to any resource (not running)"
    exit 0
fi

if [ "$(wc -l < hostlists/tags/$tag)" = "0" ]; then
    echo "    Tag does not contain any resources (not running)"
    exit 0
fi

pssh -p 50 -t 0 -i -h hostlists/tags/$tag "cd azhpc_install_config; sudo scripts/lfsrepo.sh '2.10'" >> install/06_lfsrepo.log 2>&1
