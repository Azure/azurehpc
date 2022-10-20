## Install and run WRF v4 and WPS v4 - Setup guide

## Install Azure CycleCloud
CycleCloud can be installed via Azure Marketplace, see this link:
[Quickstart - Install via Marketplace - Azure CycleCloud | Microsoft Docs](https://learn.microsoft.com/en-us/azure/cyclecloud/qs-install-marketplace?view=cyclecloud-8)

After installation, to create clusters, CycleCloud will need to use a [“Managed Identity”](https://learn.microsoft.com/en-us/azure/cyclecloud/how-to/managed-identities?view=cyclecloud-8) or “Service Principal” (either of which may need access granting via IT), to create/destroy resources.  Managed Identities is the route preferred if CycleCloud will only be creating clusters in a single Azure subscription. 

## Create NFS Storage cluster
-	It can be possible to include an external NFS share at this point (in the example, I have shared from an NFS cluster using on CycleCloud template)

Add Picture1
Add Picture2
Add Picture3

Changes:
-	Change OS to use CentOS 7 versions
-	Use +300GB storage size (space to download WRF data)
-	Change cloud-init

```
#!/bin/bash

set -x
yum install -y epel-release
yum install -y Lmod at
systemctl enable --now atd.service
cat <<EOF>/mnt/exportfs.sh
#!/bin/bash
set -x
mkdir -p /mnt/exports/data /mnt/exports/apps
sudo exportfs -o rw,sync,no_root_squash 10.4.0.0/20:/mnt/exports/data
sudo exportfs -o rw,sync,no_root_squash 10.4.0.0/20:/mnt/exports/apps
EOF
chmod 755 /mnt/exportfs.sh
at now + 2 minute -f /mnt/exportfs.sh
```

Connect to NFS storage cluster and check mounts:
```
# check mount
sudo exportfs -s
showmount -e 10.4.4.4
```

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

> Note : It's important to be connected with the hpcuser which have a shared home, versus hpcadmin which doesn't and can't run pbs jobs

## Installation

### Run wrf install script
```
# MPI_TYPE : openmpi or mvapich2
# SKU_TYPE : hb, hbv2, hc
# OMP : leave empty for none or use omp as a value
apps/wrf/build_wrf.sh <MPI_TYPE> <SKU_TYPE> <OMP>
```

Run the WPS installation script if you need to install WPS (WRF needs to be installed first)
```
# MPI_TYPE : openmpi or mvapich2
# SKU_TYPE : hb, hbv2, hc
apps/wrf/build_wps.sh <MPI_TYPE> <SKU_TYPE> 
```

## Running


Now, you can run wrf as follows:

```
qsub -l select=2:ncpus=60:mpiprocs=15,place=scatter:excl -v SKU_TYPE=hb,INPUTDIR=/path/to/inputfiles apps/wrf/run_wrf_openmpi.pbs

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
