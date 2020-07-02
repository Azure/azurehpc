#!/bin/bash

# expecting to be in $tmp_dir
cd "$( dirname "${BASH_SOURCE[0]}" )/.."

tag=${1:-lustre}

if [ ! -f "hostlists/tags/$tag" ]; then
    echo "    Tag is not assigned to any resource (not running)"
    exit 0
fi

if [ "$(wc -l < hostlists/tags/$tag)" = "0" ]; then
    echo "    Tag does not contain any resources (not running)"
    exit 0
fi

pssh -p 50 -t 0 -i -h hostlists/tags/$tag "cd azhpc_install_config; sudo scripts/lfshsm.sh '$(head -n1 hostlists/tags/lustre)' 'lustretesting' 'TXOO/DhcJHGjjcNQ58f9SGCRF3RUuz3/UHaE70KbDAHhIkd38Ic5YXVlFcdxuytgk8pDg0sp5J9lCdOWr++sXA==' 'hsm' '2.10'" >> install/15_lfshsm.log 2>&1
