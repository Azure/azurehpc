#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/azhpc-library.sh"

read_os
case "$os_maj_ver" in
    7)
        filename=pbspro_19.1.3.centos_7.zip
        url=https://github.com/PBSPro/pbspro/releases/download/v19.1.3/$filename
    ;;
    8)
        filename=openpbs_20.0.1.centos_8.zip
        url=https://github.com/openpbs/openpbs/releases/download/v20.0.1/$filename
    ;;
esac

if [ ! -f "$filename" ];then
    wget -q $url
    unzip $filename
fi

