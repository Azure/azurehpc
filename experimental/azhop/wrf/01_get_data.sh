#!/bin/bash
DATA_DIR=~/wrf/input

d=$(date +"%Y%m%d")
hour=$(date +"%H")

if [ $hour -le 9 ]; then
  ref_hour="00"
elif [ $hour -le 15 ]; then
  ref_hour="06"
elif [ $hour -le 21 ]; then
  ref_hour="12"
else
  ref_hour="18"
fi

mkdir -p $DATA_DIR
rm $DATA_DIR/*

URL="https://ftp.ncep.noaa.gov/data/nccf/com/gfs/prod/gfs.${d}/${ref_hour}/atmos/gfs.t${ref_hour}z.pgrb2.1p00.f"

pushd $DATA_DIR
for h in {0..48..3}; do
  str=$(printf "%03d" $h)
  wget $URL$str
done

popd
