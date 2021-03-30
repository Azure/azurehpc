#!/bin/bash

sas_key="$1"
sa_account=$2

d=$(date +"%Y%m%d")
h=$(date +"%H")

if [ $h -le 10 ]; then
  ref_hour="00"
elif [ $h -le 16 ]; then
  ref_hour="06"
elif [ $h -le 22 ]; then
  ref_hour="12"
else
  ref_hour="18"
fi

rm ./wrf/input/*
echo "Downloading GFS input for $d $ref_hour"
azcopy cp "https://$sa_account.blob.core.windows.net/noaa/gfs.$d/$ref_hour/atmos/*?${sas_key}" "./wrf/input" 

ls -al ./wrf/inpu