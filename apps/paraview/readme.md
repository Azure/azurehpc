# Paraview installation instructions

## Prerequisites
None

## Install paraview from binary zip file

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

    azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.


> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

To install Windows paraview on the fileshare /apps.
```
azhpc-run -u hpcuser ${azhpc_dir}/apps/paraview/install_paraview_v5.6.1.sh
```
