#!/bin/bash

# TODO: install directory
INSTALL_DIR="/data/spectrex/"


WORKING_DIR="/mnt/resource"
CADENCE_TOOLS_BLOB="https://edarg3diag.blob.core.windows.net/edatools/Cadence"
ISCAPE_FILE="IScape04.23-s012lnx86.t.Z"

cd ${WORKING_DIR}

install_required_packages()
{
        echo "----------------------installing required packages."
        sudo yum -y install ksh
        sudo yum -y install mesa-libGLU
        sudo yum -y install motif
        sudo yum -y redhat-lsb
        sudo yum -y install glibc.i686
        sudo yum -y install elfutils-libelf.i686
        sudo yum -y install mesa-libGL.i686
        sudo yum -y install mesa-libGLU.i686
        sudo yum -y install motif.i686
        sudo yum -y install redhat-lsb.i686
        sudo yum -y install glibc-devel.i686
        sudo yum -y install libXScrnSaver.i686
        sudo yum -y install libXScrnSaver.x86_64
        sudo yum -y install java-1.8.0-openjdk
}

install_iscape()
{
        echo "----------------------installing IScape."
        sudo wget ${CADENCE_TOOLS_BLOB}/${ISCAPE_FILE}
        sudo zcat ${ISCAPE_FILE} | sudo tar -xvf -
}

download_archive()
{
        echo "----------------------downloading archive."
        cd ${WORKING_DIR}
        sudo wget ${CADENCE_TOOLS_BLOB}/SpectreXArchive.tgz
        sudo tar -xzvf SpectreXArchive.tgz
}

install_from_archive()
{
        echo "---------------------installing from archive."
        cd ${WORKING_DIR}/iscape.04.23-s012/bin
        sudo ./iscape.sh -batch majorAction=installfromarchive ArchiveDirectory=${WORKING_DIR}/SpectreXArchive/ InstallDirectory=${INSTALL_DIR}

        # generate configuration scripts
        sudo ./iscape.sh -batch majorAction=configure InstallDirectory=${INSTALL_DIR}

        # complete configuration
        sudo /bin/sh ${INSTALL_DIR}installData/SPECTRE191_lnx86/batch_configure.sh
        # test
        sudo ./iscape.sh -batch majorAction=test InstallDirectory=${INSTALL_DIR}

        # example
        cd ${INSTALL_DIR}
        sudo wget ${CADENCE_TOOLS_BLOB}/spectre_example.tgz
        sudo tar -xzvf spectre_example.tgz
}

install_required_packages
install_iscape
download_archive
install_from_archive

echo "-----------------------DONE."
