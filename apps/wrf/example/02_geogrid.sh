#!/bin/bash

d=$(date +"%Y-%m-%d")
h=$(date +"%H")
#day=$(date +"%d")
#end_day=$((day+2))

if [ $h -le 10 ]; then
  ref_hour="00"
elif [ $h -le 16 ]; then
  ref_hour="06"
elif [ $h -le 22 ]; then
  ref_hour="12"
else
  ref_hour="18"
fi

# start_date = '2021-03-17_06:00:00'
start_date="${d}_${ref_hour}:00:00"
NEXT_DATE=$(date +%Y-%m-%d -d "$DATE + 1 day")
end_date="${NEXT_DATE}_${ref_hour}:00:00"
sed "s/__END_DATE__/$end_date/g;s/__START_DATE__/$start_date/g" namelist.tpl.wps > ./wrf/namelist.wps

cat ./wrf/namelist.wps

cp namelist.tpl.input wrf/namelist.input
year=$(date +"%Y")
month=$(date +"%m")
day=$(date +"%d")

sed -i 's/^[\ ]*start_year[\ ]*=[\ ]*.*$/ start_year = '"$year"',/g' ./wrf/namelist.input
sed -i 's/^[\ ]*start_month[\ ]*=[\ ]*.*$/ start_month = '"$month"',/g' ./wrf/namelist.input
sed -i 's/^[\ ]*start_day[\ ]*=[\ ]*.*$/ start_day = '"$day"',/g' ./wrf/namelist.input
sed -i 's/^[\ ]*start_hour[\ ]*=[\ ]*.*$/ start_hour = '"$ref_hour"',/g' ./wrf/namelist.input

year=$(date +"%Y" -d "$DATE + 1 day")
month=$(date +"%m" -d "$DATE + 1 day")
day=$(date +"%d" -d "$DATE + 1 day")
sed -i 's/^[\ ]*end_year[\ ]*=[\ ]*.*$/ end_year = '"$year"',/g' ./wrf/namelist.input
sed -i 's/^[\ ]*end_month[\ ]*=[\ ]*.*$/ end_month = '"$month"',/g' ./wrf/namelist.input
sed -i 's/^[\ ]*end_day[\ ]*=[\ ]*.*$/ end_day = '"$day"',/g' ./wrf/namelist.input
sed -i 's/^[\ ]*end_hour[\ ]*=[\ ]*.*$/ end_hour = '"$ref_hour"',/g' ./wrf/namelist.input


cat ./wrf/namelist.input

pushd wrf
geogrid.exe
popd
