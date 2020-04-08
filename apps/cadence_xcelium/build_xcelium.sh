#!/bin/bash

WORKING_DIR="/mnt/resource"
INSTALL_DIR="/datadrive"
CADENCE_TOOLS_BLOB="https://edatools.blob.core.windows.net/cadence/"
ISCAPE_FILE="IScape04.23-s012lnx86.t.Z"

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

install_iscape()
{
        echo "----------------------installing IScape."
        sudo wget ${CADENCE_TOOLS_BLOB}IScape/${ISCAPE_FILE}
        sudo zcat ${ISCAPE_FILE} | sudo tar -xvf -
        cd ${WORKING_DIR}/iscape.04.23-s012/bin
}

download_xcelium()
{
        echo "----------------------downloading Xcelium."
        sudo wget -P /mnt/resource/xcelium ${CADENCE_TOOLS_BLOB}Xcelium/root/http_sw_cadence_com_is_XCELIUM2003_lnx86_Base/Base_XCELIUMMAIN20.03.001_lnx86.sdx
        sudo wget -P /mnt/resource/xcelium ${CADENCE_TOOLS_BLOB}Xcelium/root/http_sw_cadence_com_is_XCELIUM2003_lnx86_Base/ic_index.sdx
}

install_xcelium()
{
        echo "---------------------installing Xcelium."
        sudo ./iscape.sh -batch majorAction=installfromarchive ArchiveDirectory=${WORKING_DIR}/xcelium/  InstallDirectory=${INSTALL_DIR}/cadence/

        # generate configuration scripts
        sudo ./iscape.sh -batch majorAction=configure InstallDirectory=${INSTALL_DIR}/cadence/

        # complete configuration
        sudo /bin/sh ${INSTALL_DIR}/cadence/installData/XCELIUM2003_lnx86/batch_configure.sh

        # test
        sudo ./iscape.sh -batch majorAction=test InstallDirectory=${INSTALL_DIR}/cadence/
}

install_required_packages
install_iscape
download_xcelium
install_xcelium

echo "-----------------------DONE."
