# Intersect installation and running instructions

## Prerequisites


## Install Intersect and eclipse from iso files

Edit variables section of full_intersect.json file, provide Port and IP address for license server (e.g 23456@17.20.20.1).
You need to be in a directory containing the config.json file, or use the -c to specify its location.
```
azhpc-install -a '${azhpc_dir}/apps/intersect/full_intersect.json'
```


## Install intersect from tarball
Edit variables section of tar_intersect.json file, provide Port and IP address for license server (e.g 23456@17.20.20.1)
You need to be in a directory containing the config.json file, or use the -c to specify its location.
```
azhpc-install -a '${azhpc_dir}/apps/intersect/tar_intersect.json'
```

## Install intersect case to run (from tarball)
You need to be in a directory containing the config.json file, or use the -c to specify its location.
```
azhpc-install -a '${azhpc_dir}/apps/intersect/case_intersect.json'
```

## Run Intersect
Intersect is run on the headnode. First, Log-in to headnode as user hpcuser (using azhpc-connect -u hpcuser).
Then git clone the azhpc repo

```
./azhpc/apps/runapp.sh -a intersect -n 2 -p 4 -s intersect_2018.2 -x "CASE WORKDIR"
```

Where CASE (e.g BO_192_192_28) is the intersect case you want to run and WORKDIR (e.g /data) is the location where your job is run.
-n 2 -p 4 (Runs the job on 2 nodes, 4 processes running on each node.)
You can moditor the intersect job progress by viewing the output file intersect_2018.2*.o*
