#!/bin/bash

# expecting to be in $tmp_dir
cd "$( dirname "${BASH_SOURCE[0]}" )/.."

tag=${1:-pbsserver}

if [ ! -f "hostlists/tags/$tag" ]; then
    echo "    Tag is not assigned to any resource (not running)"
    exit 0
fi

if [ "$(wc -l < hostlists/tags/$tag)" = "0" ]; then
    echo "    Tag does not contain any resources (not running)"
    exit 0
fi

pscp.pssh -p 50 -h hostlists/tags/$tag pbspro_19.1.1.centos7/pbspro-server-19.1.1-0.x86_64.rpm $(pwd) >> install/20_pbsserver.log 2>&1
pssh -p 50 -t 0 -i -h hostlists/tags/$tag "cd azhpc_install_config; sudo scripts/pbsserver.sh" >> install/20_pbsserver.log 2>&1
