#!/bin/bash

WORKING_DIR="/mnt/resource"
INSTALL_DIR="/datadrive"
CADENCE_TOOLS_BLOB="https://edatools.blob.core.windows.net/cadence/"
SSV_FILE="SSV-19.13-s079_1-lnx86.tar.gz"
TEMPUS_FILE="Tempus171_RAK.tar.gz"

cd ${WORKING_DIR}

install_required_packages()
{
	echo "----------------------installing required packages."
	sudo yum install ksh
	sudo yum install mesa-libGLU
	sudo yum install motif
	sudo yum redhat-lsb
	sudo yum install glibc.i686
	sudo yum install elfutils-libelf.i686
	sudo yum install mesa-libGL.i686
	sudo yum install mesa-libGLU.i686
	sudo yum install motif.i686
	sudo yum install redhat-lsb.i686
	sudo yum install glibc-devel.i686
	sudo yum install libXScrnSaver.i686
	sudo yum install libXScrnSaver.x86_64
}

get_ssv()
{
	echo "----------------------getting SSV_191."
	if [ ! -f ${SSV_FILE} ]
	then
		sudo wget ${CADENCE_TOOLS_BLOB}${SSV_FILE}
	fi
	sudo tar xfz ${SSV_FILE}
	sudo mv lnx86/ ${INSTALL_DIR}/SSV191
}

get_tempus()
{
	echo "-----------------------getting Tempus_171."
	if [ ! -f ${TEMPUS_FILE} ] 
	then
		sudo wget ${CADENCE_TOOLS_BLOB}${TEMPUS_FILE}
	fi
	sudo mkdir ${INSTALL_DIR}/work
	sudo tar xfz ${TEMPUS_FILE} -C ${INSTALL_DIR}/work
}

install_required_packages
get_ssv
get_tempus

SSV191=${INSTALL_DIR}/SSV191
export PATH=${SSV191}/bin:${SSV191}/tools.lnx86/bin:$PATH
sudo ln -s /datadrive/work .
sudo chown -R ${USER} work/
echo "-----------------------DONE."


