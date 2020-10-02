#!/bin/bash

# arg: $1 = raid_device (e.g. /dev/md10)
# arg: $* = devices to use (can use globbing)

# Check to see if this script was already run
if [ -f "/etc/mdadm.conf" ];then
    echo "Script does not need to be rerun. Exiting"
    exit 0
fi

raid_device=$1
shift

devices=
while (( "$#" )); do
    devices="$devices $1"
    shift
done

# Check to see which OS this is running on. 
os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
os_maj_ver=$(cat /etc/os-release | grep "^VERSION_ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')
echo "OS Release: $os_release"
echo "OS Major Version: $os_maj_ver"

if [ "$os_release" == "ubuntu" ];then
    tmp1=$(for x in `ls -1 /dev | grep ^sd | awk '{print $1}'`;do val=$(basename $x);prefix=$(printf '%s\n' "${val//[[:digit:]]/}");echo $prefix;done | uniq)
    tmp2=$(for x in `mount | grep "/dev/sd" | awk '{print $1}'`;do val=$(basename $x);prefix=$(printf '%s\n' "${val//[[:digit:]]/}");echo $prefix;done | uniq)

    declare -a sdisks edisks

    sdisks=( $tmp1 )
    edisks=( $tmp2 )

    echo ${sdisks[@]}
    echo ${edisks[@]}

    for target in "${edisks[@]}"; do
      for i in "${!sdisks[@]}"; do
        if [[ ${sdisks[i]} = $target ]]; then
          unset 'sdisks[i]'
        fi
      done
    done

    echo ${sdisks[@]}
    # Check if remaining disks are the same size
    declare -a disk_sizes
    for disk in "${sdisks[@]}"
    do
            echo $disk
            disk_sizes+=($(fdisk -l /dev/$disk | grep ^Disk | awk '{print $3 "-" $4 }'))
    done

    size_cnt=( $((IFS=$'\n'; sort <<< "${disk_sizes[*]}") | uniq -c ) )

    len=${#size_cnt[@]}
    echo "Length: $len"
    if [ "$len" == "2" ];then
        echo ${size_cnt[@]}
        # Add the path back
        for i in "${!sdisks[@]}"; do
            sdisks[i]="/dev/${sdisks[i]}"
        done    
        devices=$(echo ${sdisks[@]})
    else
        echo "More work needs to be done"
        exit 1
    fi
fi
echo "devices=$devices"

# print partition information
parted -s --list 2>/dev/null

# creating the partitions
for disk in $devices; do
    echo "partitioning $disk"
    parted -s $disk "mklabel gpt"
    parted -s $disk -a optimal "mkpart primary 1 -1"
    parted -s $disk print
    parted -s $disk "set 1 raid on"
done

# make sure all the partitions are ready
sleep 10
# get the partition names
partitions=
for disk in $devices; do
    partitions="$partitions $(lsblk -no kname -p $disk | tail -n1)"
done
echo "partitions=$partitions"

ndevices=$(echo $partitions | wc -w)

echo "creating raid device"
mdadm --create $raid_device --level 0 --raid-devices $ndevices $partitions || exit 1
sleep 10

mdadm --verbose --detail --scan > /etc/mdadm.conf
