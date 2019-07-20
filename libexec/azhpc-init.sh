#!/bin/bash

azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$azhpc_dir/libexec/common.sh"

config_file="config.json"

DEBUG_ON=0
COLOR_ON=1

function usage() {
    echo "Command:"
    echo "    $0 [options] resource"
    echo
    echo "Arguments"
    echo "    -h --help        : diplay this help"
    echo "    -c --config PATH : file/directory with config files"
    echo "    -d --dir DIR     : output directory"
    echo "    -v --vars VAR=VAL: vars to replace - mutliple with commas"
    echo "    -s --show        : show command for all vars not set"
    echo
}

config_path=
dir_name=.
vars_opts=
show=0

while true; do
    case $1 in
        -h|--help)
        usage
        exit 0
        ;;
        -c|--config)
        config_path="$2"
        shift
        shift
        ;;
        -d|--dir)
        dir_name="$2"
        shift
        shift
        ;;
        -v|--vars)
        vars_opts="$2"
        shift
        shift
        ;;
        -s|--show)
        show=1
        shift
        shift
        ;;
        *)
        break
    esac
done

if [ "$show" = "1" ]; then
    v=()
    for f in $(find $config_path -name "*.json"); do
        v+=($(jq -r '.variables | with_entries(select(.value=="<NOT-SET>")) | keys | join("\n")' $f))
    done

    uv=($(printf "%s\n" "${v[@]}" | sort -u))
    printf -v v_str '%s=,' "${uv[@]}"
    v_str=${v_str::-1}

    status "variables to set: \"-v $v_str\""
    exit 0
fi

if [ ! -e $config_path ]; then
    error "$config_path does not exist as a file or directory"
fi

status "creating directory $dir_name"
mkdir -p $dir_name
if [ -f $config_path ]; then
    status "copying $config_file to $dir_name"
    cp $config_path $dir_name/.
elif [ -d $config_path ]; then
    status "copying contents of $config_path to $dir_name"
    cp -r $config_path/* $dir_name/.
fi

if [ "$vars_opts" != "" ]; then
    jq_replace=
    for var in $(tr ',' '\n' <<< $vars_opts); do
        n=${var%%=*}
        v=${var#*=}
        if [ "$jq_replace" != "" ]; then
            jq_replace="${jq_replace} | "
        fi
        jq_replace="${jq_replace}.variables.${n}=\"${v}\""
    done

    for f in $(find $dir_name -name "*.json"); do
        status "updating file $f"
        jq "$jq_replace" $f >${f}.new
        mv ${f}.new $f
    done
fi
