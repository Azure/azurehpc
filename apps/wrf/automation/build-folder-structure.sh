#!/bin/bash

WRFDAT="/data/wrfdata"

echo "creating ${WRFDAT}/wpsdir/"
mkdir -p ${WRFDAT}/wpsdir/

echo "creating ${WRFDAT}/wrfdir/"
mkdir -p ${WRFDAT}/wrfdir/

echo "creating ${WRFDAT}/tables/wps/"
mkdir -p ${WRFDAT}/tables/wps/

echo "creating ${WRFDAT}/tables/wrf/"
mkdir -p ${WRFDAT}/tables/wrf/

echo "creating ${WRFDAT}/tables/namelist/"
mkdir -p ${WRFDAT}/tables/namelist/

echo "creating ${WRFDAT}/gfs_files/"
mkdir -p ${WRFDAT}/gfs_files/

echo "creating /apps/scripts/"
mkdir -p /apps/scripts/

echo "copying namelist.wps"
cp namelist.wps ${WRFDAT}/tables/namelist/namelist.wps

echo "copying namelist.input"
cp namelist.input ${WRFDAT}/tables/namelist/namelist.input

echo "copying scripts"
cp fwddatan.awk /apps/scripts/
cp get_gfs_data.py /apps/scripts/


