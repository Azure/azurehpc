#!/bin/bash

hostfile=$1
ppn=$2
metadata_nodes=${3:-1}
np=$(( $ppn * $(wc -l <$hostfile) ))

# Force Beeond to be stopped in case of any leftover daemons
start_time=$SECONDS
sudo beeond stop -P -n $hostfile -L -d
sudo beeond start -F -P -n $hostfile -m $metadata_nodes -d /localnvme/beeond -c /beeond
end_time=$SECONDS
start_time=$(($end_time - $start_time))
echo "BEEOND Started in $start_time"


source /etc/profile.d/modules.sh
export MODULEPATH=$MODULEPATH:/apps/modulefiles

module load gcc-9.2.0
module load mpi/impi_2018.4.274
module load io500-app

cat <<EOF >config.ini
[global]
datadir = /beeond/out/
resultdir = /data/results/

#verbosity = 10
timestamp-resultdir = TRUE
#drop-caches = TRUE

# Chose parameters that are very small for all benchmarks

[debug]
#stonewall-time = 1
stonewall-time = 300 # for testing

[ior-easy]
transferSize = 4m
blockSize = 16G
# 112800m
# 72000m - not enough
# 51200m was not enough for stonewall=300
# 102400m
# 1024000m

[mdtest-easy]
# The API to be used
API = POSIX
# Files per proc
n = 5000000
# 500000 - small for multiple MDS
# 1000000

[ior-hard]
# The API to be used
API = POSIX
# Number of segments  10000000
segmentCount = 2200000

# 400000
# 95000

[mdtest-hard]
# The API to be used
API = POSIX
# Files per proc 1000000
n = 160000


[find]
#external-script = /mnt/beeond/io500-app/bin/pfind
# no need to set stonewall time or result directory  - let it use the defaults
#external-extra-args =  -s \$io500_stonewall_timer -r \$io500_result_dir/pfind_results
# below is used by io500.sh only.  The io500 C app will not use, since we are not using some external script, we want to use default pfind. For io500, you can set the -N and -q values using pfind-queue-length, pfind-steal-next
#external-extra-args = -N -q 15000
#external-args =  -s $io500_stonewall_timer -r $io500_result_dir/pfind_results
#nproc = 30
#pfind-queue-length = 15000
#pfind-steal-next = TRUE
#pfind-parallelize-single-dir-access-using-hashing = TRUE
EOF

mpirun -np $np -ppn $ppn -hostfile $hostfile io500 config.ini

start_time=$SECONDS
sudo beeond stop -P -n $hostfile -L -d
end_time=$SECONDS
stop_time=$(($end_time - $start_time))
echo "BEEOND Stopped in $stop_time"
