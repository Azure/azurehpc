#!/bin/bash

# parameters that can be overridden
ABAQUS_INSTALLER_DIR=${ABAQUS_INSTALLER_DIR:-/mnt/resource}
#NOTE!!!! Update the below details before running the script
LICENSE_SERVER="${LICENSE_SERVER_IP}"

LICIP=27000@${LICENSE_SERVER}
echo $LICIP

source /opt/intel/impi/*/bin64/mpivars.sh

#echo "----- patch OS -----"
sudo yum install -y ksh 
sudo yum install -y lsb 

sudo mkdir -p /apps/abaqus/applications
sudo mkdir -p /apps/abaqus/INSTALLERS
sudo chmod -R 777 /apps/abaqus

#Get Abaqus bits
echo "----- get Abaqus install bits -----"
cd /apps/abaqus/INSTALLERS
tar -xvf "${ABAQUS_INSTALLER_DIR}/2019.AM_SIM_Abaqus_Extend.AllOS.1-5.tar"  
tar -xvf "${ABAQUS_INSTALLER_DIR}/2019.AM_SIM_Abaqus_Extend.AllOS.2-5.tar"  
tar -xvf "${ABAQUS_INSTALLER_DIR}/2019.AM_SIM_Abaqus_Extend.AllOS.3-5.tar"  
tar -xvf "${ABAQUS_INSTALLER_DIR}/2019.AM_SIM_Abaqus_Extend.AllOS.4-5.tar"  
tar -xvf "${ABAQUS_INSTALLER_DIR}/2019.AM_SIM_Abaqus_Extend.AllOS.5-5.tar" 

echo "----- install Abaqus solvers -----"
cat << EOF |  ksh /apps/abaqus/INSTALLERS/AM_SIM_Abaqus_Extend.AllOS/3/SIMULIA_AbaqusServices/Linux64/1/StartTUI.sh

/apps/abaqus/applications/DassaultSystemes/SimulationServices/V6R2019x









EOF

rm -rf /apps/abaqus/applications/SIMULIA/CAE/2019/linux_a64

# do not check the license during installation.
export NOLICENSECHECK=true
echo "----- install Abaqus services -----"
cat << EOF |  ksh /apps/abaqus/INSTALLERS/AM_SIM_Abaqus_Extend.AllOS/4/SIMULIA_Abaqus_CAE/Linux64/1/StartTUI.sh

/apps/abaqus/applications/SIMULIA/CAE/2019

$LICIP


/apps/abaqus/applications/DassaultSystemes/SimulationServices/V6R2019x
/apps/abaqus/applications/DassaultSystemes/SIMULIA/Commands
/apps/abaqus/applications/DassaultSystemes/SIMULIA/CAE/plugins/2019









EOF

ENV_PATH="/apps/abaqus/applications/DassaultSystemes/SimulationServices/V6R2019x/linux_a64/SMA/site"

# Need to path the impi.env file to use the right intel mpi path
cat <<EOF >$ENV_PATH/impi.env

#-*- mode: python -*-

import driverUtils, os

impipath = driverUtils.locateFile(os.environ.get('I_MPI_ROOT', ''), 'bin64', 'mpirun')
mp_mpirun_path = {IMPI: impipath}
mp_rsh_command = 'ssh -n -l %U %H %C'

# bump up the socket buffer size to 132K
os.environ.setdefault('MPI_SOCKBUFSIZE', '131072')

#if not self.mpiEnv.get('MPI_RDMA_MSGSIZE', None):
#    os.environ['MPI_RDMA_MSGSIZE'] = '16384,1048576,4194304'

del impipath
# 

EOF

# Need to specify we are using Intel MPI in mpi_config.env
replace="s,mp_mpi_implementation = PMPI,#mp_mpi_implementation = PMPI,g"
replace+=";s,#mp_mpi_implementation = IMPI,mp_mpi_implementation = IMPI,g"
cp $ENV_PATH/mpi_config.env $ENV_PATH/mpi_config.env.bak
sed "$replace" $ENV_PATH/mpi_config.env.bak > $ENV_PATH/mpi_config.env

cat $ENV_PATH/mpi_config.env