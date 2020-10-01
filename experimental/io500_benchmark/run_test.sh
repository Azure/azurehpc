#!/bin/bash

N=$1
PPN=$2

echo "Running $N nodes with $PPN ppn"

cd $HOME
source azurehpc/install.sh

cp -r hbv2_io500_impi hbv2_io500_impi_${N}x${PPN}
cd hbv2_io500_impi_${N}x${PPN}
sed -i "s/__N__/$N/g;s/__PPN__/$PPN/g" config.json

azhpc-build
azhpc-scp -- -r hpcadmin@headnode:/data/results .
azhpc-destroy --force --no-wait
