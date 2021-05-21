#!/bin/bash
DATA_DIR=~/wrf/input

d=$(date +"%Y-%m-%d")
h=$(date +"%H")

if [ $h -le 9 ]; then
  ref_hour="00"
elif [ $h -le 15 ]; then
  ref_hour="06"
elif [ $h -le 21 ]; then
  ref_hour="12"
else
  ref_hour="18"
fi

# start_date = '2021-03-17_06:00:00'
start_date="${d}_${ref_hour}:00:00"
NEXT_DATE=$(date +%Y-%m-%d -d "$DATE + 1 day")
end_date="${NEXT_DATE}_${ref_hour}:00:00"
sed "s/__END_DATE__/$end_date/g;s/__START_DATE__/$start_date/g" namelist.tpl.wps > $DATA_DIR/namelist.wps

cat $DATA_DIR/namelist.wps

cp namelist.tpl.input $DATA_DIR/namelist.input
year=$(date +"%Y")
month=$(date +"%m")
day=$(date +"%d")

sed -i 's/^[\ ]*start_year[\ ]*=[\ ]*.*$/ start_year = '"$year"',/g' $DATA_DIR/namelist.input
sed -i 's/^[\ ]*start_month[\ ]*=[\ ]*.*$/ start_month = '"$month"',/g' $DATA_DIR/namelist.input
sed -i 's/^[\ ]*start_day[\ ]*=[\ ]*.*$/ start_day = '"$day"',/g' $DATA_DIR/namelist.input
sed -i 's/^[\ ]*start_hour[\ ]*=[\ ]*.*$/ start_hour = '"$ref_hour"',/g' $DATA_DIR/namelist.input

year=$(date +"%Y" -d "$DATE + 1 day")
month=$(date +"%m" -d "$DATE + 1 day")
day=$(date +"%d" -d "$DATE + 1 day")
sed -i 's/^[\ ]*end_year[\ ]*=[\ ]*.*$/ end_year = '"$year"',/g' $DATA_DIR/namelist.input
sed -i 's/^[\ ]*end_month[\ ]*=[\ ]*.*$/ end_month = '"$month"',/g' $DATA_DIR/namelist.input
sed -i 's/^[\ ]*end_day[\ ]*=[\ ]*.*$/ end_day = '"$day"',/g' $DATA_DIR/namelist.input
sed -i 's/^[\ ]*end_hour[\ ]*=[\ ]*.*$/ end_hour = '"$ref_hour"',/g' $DATA_DIR/namelist.input


cat $DATA_DIR/namelist.input

. ~/spack/share/spack/setup-env.sh
module use /usr/share/Modules/modulefiles
spack load wps
WPS_ROOT=$(spack location -i wps)
pushd $DATA_DIR
geogrid.exe
popd
