# Run the OSU benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.
OSU Benchmarks are already provided in the CentOS 7.6 HPC Image, so there is no need to build them if you use that image.

Dependencies for binary version:

* None

First copy the apps directory to the cluster in a shared directory.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -r $azhpc_dir/apps/. hpcuser@headnode:/apps
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Running

### With LSF
Now, you can run as follows:

```
bsub -R "span[ptile=1]" -n 2 -o %J.log -e %J.err < ringpingpong.lsf
```

