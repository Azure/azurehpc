#!/bin/bash -x
  
# Check to see which OS this is running on. 
os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
os_maj_ver=$(cat /etc/os-release | grep "^VERSION_ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')

version=`wget -O - https://www.openpbs.org/Download.aspx#download | grep -i \<h5\>OpenPBS | awk '{print $2}'`
pbs_ver=${version::${#version}-6}

echo "OS Release: $os_release"
echo "OS Major Version: $os_maj_ver"
# Script to be run on all compute nodes
if [ "$os_release" == "centos" ];then
    filename=openpbs_${pbs_ver}.centos_8.zip
elif [ "$os_release" == "ubuntu" ];then
    filename=openpbs_${pbs_ver}.ubuntu_1804.zip
fi

echo "$filename"

if [ "$os_release" == "centos" ] && [ "$os_maj_ver" == "7" ];then
    filename=pbspro_19.1.1.centos7.zip

    if [ ! -f "$filename" ];then
        wget -q https://github.com/PBSPro/pbspro/releases/download/v19.1.1/$filename
        unzip $filename
    fi
else
    if [ ! -f "$filename" ];then
        wget -q http://wpc.23a7.iotacdn.net/8023A7/origin2/rl/OpenPBS/$filename
        unzip $filename
    fi
fi
