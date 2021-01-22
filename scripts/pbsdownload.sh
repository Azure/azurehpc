#!/bin/bash

filename=pbspro_19.1.3.centos_7.zip

if [ ! -f "$filename" ];then
    wget -q https://github.com/PBSPro/pbspro/releases/download/v19.1.3/$filename
    unzip $filename
fi

