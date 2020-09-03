#!/bin/bash
set -x
LICENSE_SERVER_IP=$1
FULL_SAS_KEY="$2"
FOLDER=$3
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LICIP=27000@${LICENSE_SERVER_IP}

APP_NAME=abaqus
DOWNLOAD_DIR=/mnt/resource/$APP_NAME
ABAQUS_INSTALLER_DIR=$DOWNLOAD_DIR/INSTALLERS
SHARED_APP=/apps

#echo "----- patch OS -----"
#yum install -y ksh 
yum install -y lsb 

mkdir -p $ABAQUS_INSTALLER_DIR

# Get Binaries from blobs
sas=$(echo ${FULL_SAS_KEY#*\?})
uri=$(echo ${FULL_SAS_KEY%\?*})

/usr/local/bin/azcopy cp "$uri/$FOLDER/*?$sas" $ABAQUS_INSTALLER_DIR --overwrite ifSourceNewer

#Get Abaqus bits
echo "----- get Abaqus install bits -----"
cd $ABAQUS_INSTALLER_DIR

if [ ! -d "AM_SIM_Abaqus_Extend.AllOS" ]; then
    tar -xvf "2020.AM_SIM_Abaqus_Extend.AllOS.1-4.tar"
    tar -xvf "2020.AM_SIM_Abaqus_Extend.AllOS.2-4.tar"
    tar -xvf "2020.AM_SIM_Abaqus_Extend.AllOS.3-4.tar"
    tar -xvf "2020.AM_SIM_Abaqus_Extend.AllOS.4-4.tar"
fi

# Configure 
echo "----- Configure UserIntentions file for silent installation -----"
sed -i "s,__TARGET_PATH__,$SHARED_APP/SIMULIA/EstProducts/2020,g" $DIR/UserIntentions.xml

echo "----- install SIMULIA Established Products -----"
./AM_SIM_Abaqus_Extend.AllOS/4/SIMULIA_EstablishedProducts/Linux64/1/StartTUI.sh --silent $DIR/UserIntentions.xml

ENV_PATH="$SHARED_APP/SIMULIA/EstProducts/2020/linux_a64/SMA/site"

# Need to path the impi.env file to use the right intel mpi path
# cat <<EOF >$ENV_PATH/impi.env

# #-*- mode: python -*-

# import driverUtils, os

# impipath = driverUtils.locateFile(os.environ.get('I_MPI_ROOT', ''), 'bin64', 'mpirun')
# mp_mpirun_path = {IMPI: impipath}
# mp_rsh_command = 'ssh -n -l %U %H %C'

# # bump up the socket buffer size to 132K
# os.environ.setdefault('MPI_SOCKBUFSIZE', '131072')

# #if not self.mpiEnv.get('MPI_RDMA_MSGSIZE', None):
# #    os.environ['MPI_RDMA_MSGSIZE'] = '16384,1048576,4194304'

# del impipath
# # 

# EOF

# Need to specify we are using Intel MPI in mpi_config.env
replace="s,mp_mpi_implementation = PMPI,#mp_mpi_implementation = PMPI,g"
replace+=";s,#mp_mpi_implementation = IMPI,mp_mpi_implementation = IMPI,g"
sed -i "$replace" $ENV_PATH/mpi_config.env 

cat $ENV_PATH/mpi_config.env