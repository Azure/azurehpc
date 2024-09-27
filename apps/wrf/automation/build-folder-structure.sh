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

echo "creating ${WRFDAT}/gfs_data/"
mkdir -p ${WRFDAT}/gfs_data/

echo "creating ${WRFDAT}/geog/"
mkdir -p ${WRFDAT}/geog/

echo "creating /apps/scripts/"
mkdir -p /apps/scripts/

echo "copying namelist*.wps"
cp -f /data/azurehpc/apps/wrf/automation/namelist*.wps ${WRFDAT}/tables/namelist/

echo "copying namelist*.input"
cp -f /data/azurehpc/apps/wrf/automation/namelist*.input ${WRFDAT}/tables/namelist/

echo "creating link to scripts"
#cd /data/azurehpc/apps/wrf/automation/
#cp /data/azurehpc/apps/wrf/automation/fwddatan.awk /apps/scripts/
#cp /data/azurehpc/apps/wrf/automation/get_gfs_data.py /apps/scripts/
#cp run_*.slurm run_*.pbs submit*.sh /apps/scripts/
ln -s /data/azurehpc/apps/wrf/automation/* /apps/scripts/

echo "creating links to WPF files"
ln -s /apps/hbv3/wps-openmpi/WPS-4.1/* /data/wrfdata/tables/wps/

echo "creating links to WRF files"
ln -s /apps/hbv3/wrf-openmpi/WRF-4.1.5/run/* /data/wrfdata/tables/wrf/

echo "Moving geog files"
#mv albedo_modis albedo_modis.tar.bz2 greenfrac_fpar_modis greenfrac_fpar_modis.tar.bz2 lai_modis_10m lai_modis_10m.tar.bz2 maxsnowalb_modis maxsnowalb_modis.tar.bz2 modis_landuse_20class_30s_with_lakes modis_landuse_20class_30s_with_lakes.tar.bz2 orogwd_10m orogwd_10m.tar.bz2 soiltemp_1deg soiltemp_1deg.tar.bz2 soiltype_bot_30s soiltype_bot_30s.tar.bz2 soiltype_top_30s soiltype_top_30s.tar.bz2 topo_10m topo_10m.tar.bz2 topo_2m topo_2m.tar.bz2 topo_30s topo_30s.tar.bz2 topo_gmted2010_30s topo_gmted2010_30s.tar.bz2 geog 

