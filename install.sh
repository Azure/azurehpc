#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -d "$DIR/bin" ]; then
    mkdir $DIR/bin
fi

if ! command -v az &> /dev/null
then
    echo "azure CLI not installed. Cannot continue"
    exit
fi

export PATH=${DIR}/bin:$PATH
export azhpc_dir=$DIR
export azhpc_pypath=$(az --version | grep "Python location" | cut -d' ' -f3 | sed "s/'//g")
if [ -e /etc/centos-release ]; then
    export AZHPC_PYTHONPATH=/usr/lib64/az/lib/python3.6/site-packages
fi

for cmd in "" build connect destroy run_install get init preprocess run scp status; do
    if [ "$cmd" = "" ]; then
        cmd_name=azhpc
        cmd_launch=azhpc.py
    else
        echo "installing $cmd" 
        cmd_name=azhpc-$cmd
        cmd_launch="azhpc.py $cmd"
    fi
    
    if [ ! -f "$DIR/bin/$cmd_name" ]; then
        cat <<EOF >$DIR/bin/$cmd_name
#!/bin/bash
#autogenerated file from azhpc install.sh
export azhpc_dir="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )/.." && pwd )"
export PYTHONPATH=\$PYTHONPATH:\$AZHPC_PYTHONPATH
exec \$azhpc_pypath \$azhpc_dir/pyazhpc/$cmd_launch \$*
EOF
        chmod +x $DIR/bin/$cmd_name
    fi
done
