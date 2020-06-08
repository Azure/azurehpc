The azhpc project for Cycle Cloud contains specs to extend cluster managed by Cycle with infrastructure blocks deployed thru azhpc.

# Install 
On the jumpbox

git clone https://github.com/Azure/azurehpc.git

cd azurehpc/cyclecloud
./install.sh

# Create Cluster
cluster=foo
template=azhpc-pbs
cyclecloud create_cluster $template $cluster -p templates/$template.json --force

# start cluster
cyclecloud start_cluster $cluster

# Wait for cluster to be ready
cyclecloud show_cluster $cluster
status=""
while status != "Started"
    status=$(cyclecloud show_cluster $cluster | grep master | xargs | cut -d' ' -f2)

# Connect to master and submit a job
cyclecloud connect master -c $cluster

# Submit simple job
qsub -l select=2:ncpus=120:mpiprocs=120,place=scatter:excl -N allreduce -k oe -j oe -- /apps/azurehpc/apps/imb-mpi/allreduce.sh impi2018

sudo /apps/azurehpc/apps/fio/build_fio.sh
qsub -l select=1:ncpus=8:mpiprocs=8,place=scatter:excl -N fio -k oe -j oe -- /apps/azurehpc/apps/fio/fio.pbs /beegfs
