#!/bin/bash
version=${1-19}

case "$version" in
    19)
        filename=pbspro_19.1.3.centos_7.zip
        url=https://github.com/openpbs/openpbs/releases/download/v19.1.3/$filename
    ;;
    20)
        filename=openpbs_20.0.1.centos_8.zip
        url=https://github.com/openpbs/openpbs/releases/download/v20.0.1/$filename
    ;;
    *)
        echo "Unknown version $version provided"
        echo "Usage : $0 {19|20}"
        exit 1
    ;;
esac

if [ ! -f "$filename" ];then
    wget -q $url
    unzip $filename
fi

