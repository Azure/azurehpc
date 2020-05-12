#!/bin/bash

filename=pbspro_19.1.1.centos7.zip

if [ ! -f "$filename" ];then
    wget -q https://github.com/PBSPro/pbspro/releases/download/v19.1.1/$filename
    unzip $filename
fi

