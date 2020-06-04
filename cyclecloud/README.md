The azhpc project for Cycle Cloud contains specs to extend cluster managed by Cycle with infrastructure blocks deployed thru azhpc.

On the jumpbox

git clone https://github.com/Azure/azurehpc.git
cd azurehpc/cyclecloud/azhpc
cyclecloud project default_locker azure-storage
cyclecloud project upload

cluster=foo
cd ..
cyclecloud import_template -f templates/azhpc-pbs.txt --force
cyclecloud create_cluster azhpc-pbs $cluster -p templates/azhpc-pbs.json --force

# start cluster
cyclecloud start_cluster $cluster

# Wait for cluster to be ready
cyclecloud show_cluster $cluster
status=""
while status != "Started"
    status=$(cyclecloud show_cluster $cluster | grep master | xargs | cut -d' ' -f2)

master=$(cyclecloud show_cluster $cluster | grep master | xargs | cut -d' ' -f3)

# Copy apps scripts to master
scp -r ~/azurehpc/apps/* $master:/share/apps

# Connect to master and submit a job
cyclecloud connect master -c $cluster

ln -s /share/apps /apps

qsub -l select=2:ncpus=120:mpiprocs=120,place=scatter:excl -- /apps/imb-mpi/allreduce.sh impi2018


sudo /apps/azurehpc/apps/fio/build_fio.sh
qsub -l select=1:ncpus=8:mpiprocs=8,place=scatter:excl -N fio -k oe -j oe -- /apps/fio/fio.pbs /beegfs
