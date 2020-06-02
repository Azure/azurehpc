#!/bin/bash

# arg: $1 = anf mount pt
anf_mount_pt=$1
if [ -z "$anf_mount_pt" ]; then
    echo "The ANF mount point is required"
    exit 1
fi

mkdir -p /share
#
chmod 777 $anf_mount_pt
#
mkdir -p $anf_mount_pt/apps
mkdir -p $anf_mount_pt/data
mkdir -p $anf_mount_pt/home
#
chmod 777 $anf_mount_pt/apps
chmod 777 $anf_mount_pt/data
chmod 777 $anf_mount_pt/home
#
if [ ! -L /apps ]; then
    ln -s $anf_mount_pt/apps /apps
fi
if [ ! -L /data ]; then
    ln -s $anf_mount_pt/data /data
fi
if [ ! -L /share/home ]; then
    ln -s $anf_mount_pt/home /share/home
fi
