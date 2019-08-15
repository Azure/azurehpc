#!/bin/bash

#NOTE!!!! Update the below details before running the script
ABAQUS_INSTALL_STORAGEENDPOINT="<installer tar storage endpoint>"
ABAQUS_INSTALL_SASKEY="<saskey>"
LICENSE_SERVER="<license server ip>"

LICIP=27000@${LICENSE_SERVER}
echo $LICIP

setup_intel_mpi_2018()
{
    echo "*********************************************************"
    echo "*                                                       *"
    echo "*           Installing Intel MPI & Tools                *" 
    echo "*                                                       *"
    echo "*********************************************************"
    VERSION=2018.4.274

    sudo yum -y install yum-utils
    sudo yum-config-manager --add-repo https://yum.repos.intel.com/mpi/setup/intel-mpi.repo
    sudo rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB

    sudo yum -y install intel-mpi-2018.4-057

              sudo mkdir -p /usr/share/Modules/modulefiles/mpi

cat << EOF >> /usr/share/Modules/modulefiles/mpi/impi-$VERSION
#%Module 1.0
#
#  Intel MPI $VERSION
#
conflict        mpi
prepend-path    PATH            /opt/intel/impi/$VERSION/intel64/bin
prepend-path    LD_LIBRARY_PATH /opt/intel/impi/$VERSION/intel64/lib
prepend-path    MANPATH         /opt/intel/impi/$VERSION/man
setenv          MPI_BIN         /opt/intel/impi/$VERSION/intel64/bin
setenv          MPI_INCLUDE     /opt/intel/impi/$VERSION/intel64/include
setenv          MPI_LIB         /opt/intel/impi/$VERSION/intel64/lib
setenv          MPI_MAN         /opt/intel/impi/$VERSION/man
setenv          MPI_HOME        /opt/intel/impi/$VERSION/intel64
EOF

    #source /opt/intel/impi/${VERSION}/bin64/mpivars.sh
}

if [ ! -d "/opt/intel/impi" ]; then
    setup_intel_mpi_2018
fi

#echo "----- patch OS -----"
sudo yum install -y ksh 
sudo yum install -y lsb 

sudo mkdir -p /apps/abaqus/applications
sudo mkdir -p /apps/abaqus/INSTALLERS
sudo mkdir -p /opt/abaqus/benchmark
sudo chmod -R 777 /apps/abaqus
sudo chmod -R 777 /opt/abaqus

#Get Abaqus bits
echo "----- get Abaqus install bits -----"
cd /apps/abaqus/INSTALLERS
wget "${ABAQUS_INSTALL_STORAGEENDPOINT}/abaqus-2019/2019.AM_SIM_Abaqus_Extend.AllOS.1-5.tar?${ABAQUS_INSTALL_SASKEY}" -O -| tar -x 
wget "${ABAQUS_INSTALL_STORAGEENDPOINT}/abaqus-2019/2019.AM_SIM_Abaqus_Extend.AllOS.2-5.tar?${ABAQUS_INSTALL_SASKEY}" -O -| tar -x 
wget "${ABAQUS_INSTALL_STORAGEENDPOINT}/abaqus-2019/2019.AM_SIM_Abaqus_Extend.AllOS.3-5.tar?${ABAQUS_INSTALL_SASKEY}" -O -| tar -x 
wget "${ABAQUS_INSTALL_STORAGEENDPOINT}/abaqus-2019/2019.AM_SIM_Abaqus_Extend.AllOS.4-5.tar?${ABAQUS_INSTALL_SASKEY}" -O -| tar -x 
wget "${ABAQUS_INSTALL_STORAGEENDPOINT}/abaqus-2019/2019.AM_SIM_Abaqus_Extend.AllOS.5-5.tar?${ABAQUS_INSTALL_SASKEY}" -O -| tar -x 

echo "----- install Abaqus solvers -----"
cat << EOF |  ksh /apps/abaqus/INSTALLERS/AM_SIM_Abaqus_Extend.AllOS/3/SIMULIA_AbaqusServices/Linux64/1/StartTUI.sh

/opt/abaqus/applications/DassaultSystemes/SimulationServices/V6R2019x









EOF

rm -rf /apps/abaqus/applications/SIMULIA/CAE/2019/linux_a64

# do not check the license during installation.
export NOLICENSECHECK=true
echo "----- install Abaqus services -----"
cat << EOF |  ksh /apps/abaqus/INSTALLERS/AM_SIM_Abaqus_Extend.AllOS/4/SIMULIA_Abaqus_CAE/Linux64/1/StartTUI.sh

/opt/abaqus/applications/SIMULIA/CAE/2019
$LICIP

/opt/abaqus/applications/DassaultSystemes/SimulationServices/V6R2019x
/opt/abaqus/applications/DassaultSystemes/SIMULIA/Commands
/opt/abaqus/applications/DassaultSystemes/SIMULIA/CAE/plugins/2019









EOF

ENV_PATH="/opt/abaqus/applications/DassaultSystemes/SimulationServices/V6R2019x/linux_a64/SMA/site"

# this is no longer needed as we set the license server in the run script
#echo abaquslm_license_file="'$LICIP'" >> $ENV_PATH/custom_v6.env
#echo license_server_type=FLEXNET  >> $ENV_PATH/custom_v6.env

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