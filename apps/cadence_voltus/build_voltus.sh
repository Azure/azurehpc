#!/bin/bash

# TODO: install directory
INSTALL_DIR="/voltus/"

WORKING_DIR="/mnt/resource"
CADENCE_TOOLS_BLOB="https://edarg3diag.blob.core.windows.net/edatools/Cadence"
ISCAPE_FILE="IScape04.23-s012lnx86.t.Z"

cd ${WORKING_DIR}

install_required_packages()
{
        echo "----------------------installing required packages."
        yum -y install ksh
        yum -y install mesa-libGLU
        yum -y install motif
        yum -y install redhat-lsb
        yum -y install glibc.i686
        yum -y install elfutils-libelf.i686
        yum -y install mesa-libGL.i686
        yum -y install mesa-libGLU.i686
        yum -y install motif.i686
        yum -y install redhat-lsb.i686
        yum -y install glibc-devel.i686
        yum -y install libXScrnSaver.i686
        yum -y install libXScrnSaver.x86_64
        yum -y install java-1.8.0-openjdk
}

install_iscape()
{
        echo "----------------------installing IScape."
        wget ${CADENCE_TOOLS_BLOB}/${ISCAPE_FILE}
        zcat ${ISCAPE_FILE} | sudo tar -xvf -
        cd ${WORKING_DIR}/iscape.04.23-s012/bin

        # To get Archive for the 1st time
        #./iscape.sh -batch majorAction=download minorAction=ArchiveInstall SourceLocation="http://sw.cadence.com/is/SSV211/lnx86/Base" ArchiveDirectory=${WORKING_DIR}/VoltusArchive/ InstallDirectory=${INSTALL_DIR}
}

download_archive()
{
        echo "----------------------downloading archive."
        cd ${WORKING_DIR}
        wget ${CADENCE_TOOLS_BLOB}/VoltusArchive.tgz
        tar -xzvf VoltusArchive.tgz
}

install_from_archive()
{
        echo "---------------------installing from archive."
        cd ${WORKING_DIR}/iscape.04.23-s012/bin
        ./iscape.sh -batch majorAction=installfromarchive ArchiveDirectory=${WORKING_DIR}/VoltusArchive/ InstallDirectory=${INSTALL_DIR}

        # generate configuration scripts
        ./iscape.sh -batch majorAction=configure InstallDirectory=${INSTALL_DIR}

        # complete configuration
        /bin/sh ${INSTALL_DIR}installData/SSV211_lnx86/batch_configure.sh
}

install_required_packages
install_iscape
download_archive
install_from_archive

echo "-----------------------DONE."
