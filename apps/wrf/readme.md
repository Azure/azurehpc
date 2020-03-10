## Install and run WRF v4 and WPS v4

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up. Spack is installed (See [here](../spack/readme.md) for details).

Dependencies for binary version:

* None


First copy the apps directory to the cluster in a shared directory.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -r $azhpc_dir/apps/. hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.


## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Installation

### Run wrf install script
```
apps/wrf/install_wrf_openmpi.sh 
```
> Note: Set SKU_TYPE to the type of sku you are using (e.h hb, hbv2 or hc). To install the hybrid parallel version use the install_wrf_omp_openmpi.sh script instead.

Run the WPS installation script if you need to install WPS (WRF needs to be installed first)
```
apps/wrf/install_wps_openmpi.sh 
```

## Running


Now, you can run wrf as follows:

```
qsub -l select=2:ncpus=60:mpiprocs=15 -v SKU_TYPE=hb,INPUTDIR=/path/to/inputfiles apps/wrf/run_wrf_openmpi.pbs

```
> Where SKU_TYPE is the sku type you are running on and INPUTDIR contains the location of wrf input files (namelist.input, wrfbdy_d01 and wrfinput_d01)

## How to create WRF input cases with WPS
WPS (WRF preprocessing system) is used to create WRF input cases. WRF v3 models are not compatible with WRF v4, so some WRF v4 input cases will need to be generated with WSP v4.
I will outline the procedure used to create a new_conus2.5km input case for WRF v4.

Git clone the following repository to get access to the WRF benchmarks cases namelist.input and namelist.wps files (which will be needed later as WPS input and an master input file for WRF).

```
git clone https://github.com/akirakyle/WRF_benchmarks.git
```

Download the raw data from https://rda.ucar.edu/datasets/ds084.1/
Go to the "data Access" section and download the following data (2018, 2018-06-17, gfs.0p25.2018061700.f000.grib2, gfs.0p25.2018061712.f384.grib2)

Modify your namelist.wps file, setting the correct paths for geog_data_path, opt_geogrid_tbl_path and opt_metgrid_tbl_path.

cd to your WPS installation directory and copy the new_conus2.5km namelist.wps to this location.

Download WPS v4 geopraphical static data for WPS v4. (https://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html), Download topo_gmted2010_30s, modis_landuse_20class_30s_with_lakes, soiltemp_1deg, soiltype_top_30s, albedo_modis, greenfrac_fpar_modis, lai_modis_10m, maxsnowalb_modis_10m and orogwd_10m. Extract into a directory.
```
mpirun ./geogrid.exe
```
The file geo_em.d01.nc should be created.
```
ln -s ungrib/Variable_Tables/Vtable.GFS Vtable
```
```
./link_grib.csh /location/of/NCEP_GFS_Model_Run_data/gfs.0p25.20180617*
```
```
./ungrib.exe >& ungrib.log
```
```
mpirun ./metgrid.exe
```
Should see the following files
```
-rw-rw-r--. 1 hpcuser hpcuser  79075286 Dec 12 04:11 met_em.d01.2018-06-17_12:00:00.nc
-rw-rw-r--. 1 hpcuser hpcuser  78622472 Dec 12 04:11 met_em.d01.2018-06-17_09:00:00.nc
-rw-rw-r--. 1 hpcuser hpcuser  79054700 Dec 12 04:10 met_em.d01.2018-06-17_06:00:00.nc
-rw-rw-r--. 1 hpcuser hpcuser  78668607 Dec 12 04:10 met_em.d01.2018-06-17_03:00:00.nc
-rw-rw-r--. 1 hpcuser hpcuser  79435709 Dec 12 04:10 met_em.d01.2018-06-17_00:00:00.nc
```
cd WRF v4 run directory
cp new_conus2.5km namelist.input to this location
cp the file met_em*.nc files to this location

```
mpirun ./real.exe
```
The following files should be generated (These are the input files required to run WRF v4)
```
-rw-rw-r--. 1 hpcuser hpcuser  31285895 Dec 12 15:50 wrfbdy_d01
-rw-rw-r--. 1 hpcuser hpcuser 127618030 Dec 12 15:50 wrfinput_d01
```
