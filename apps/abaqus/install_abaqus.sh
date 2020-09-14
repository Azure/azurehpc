#!/bin/bash
LICENSE_SERVER_IP=$1
FULL_SAS_KEY="$2"
FOLDER=$3
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LICIP=27000@${LICENSE_SERVER_IP}

APP_NAME=abaqus
DOWNLOAD_DIR=/mnt/resource/$APP_NAME
ABAQUS_INSTALLER_DIR=$DOWNLOAD_DIR/INSTALLERS
SHARED_APPS=/apps

#echo "----- patch OS -----"
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
sed -i "s,__SHARED_APPS__,$SHARED_APPS,g" $DIR/UserIntentions.xml
sed -i "s,__LIC_IP__,$LICIP,g" $DIR/UserIntentions.xml

echo "----- install SIMULIA Established Products -----"
./AM_SIM_Abaqus_Extend.AllOS/4/SIMULIA_EstablishedProducts/Linux64/1/StartTUI.sh --silent $DIR/UserIntentions.xml

ENV_PATH="$SHARED_APPS/SIMULIA/EstProducts/2020/linux_a64/SMA/site"

# Need to specify we are using Intel MPI in mpi_config.env
replace="s,mp_mpi_implementation = PMPI,#mp_mpi_implementation = PMPI,g"
replace+=";s,#mp_mpi_implementation = IMPI,mp_mpi_implementation = IMPI,g"
sed -i "$replace" $ENV_PATH/mpi_config.env 
