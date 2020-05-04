#!/bin/bash

WORKING_DIR="/mnt/resource"
INSTALL_DIR="/share"
CADENCE_TOOLS_BLOB="https://edatools.blob.core.windows.net/cadence/"
SPECTRE_FILE="SPECTRE191_ISR5.tar.gz"
EXAMPLE_FILE="spectre_example.tar.gz"

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
        sudo yum -y install redhat-lsb.x86_64
        sudo yum -y install glibc-devel.i686
        sudo yum -y install libXScrnSaver.i686
        sudo yum -y install libXScrnSaver.x86_64
}

get_spectre()
{
        echo "----------------------getting Spectre_ISR5."
        if [ ! -f ${SPECTRE_FILE} ]
        then
                sudo wget -P ${WORKING_DIR} ${CADENCE_TOOLS_BLOB}${SPECTRE_FILE}

        fi
        sudo wget -P sudo wget -P ${WORKING_DIR} ${CADENCE_TOOLS_BLOB}${EXAMPLE_FILE}
        sudo mkdir ${INSTALL_DIR}/Spectre_ISR5
        sudo tar xfz ${SPECTRE_FILE} -C ${INSTALL_DIR}/Spectre_ISR5
        sudo tar xfz ${EXAMPLE_FILE} -C ${INSTALL_DIR}/Spectre_ISR5
}

install_required_packages
get_spectre

/bin/csh


setenv MMSIMHOME /share/Spectre_ISR5/SPECTRE191_ISR5

set path = (.  ./bin ~/bin /usr/sbin /sbin /usr/dt/bin /usr/openwin/bin \
            /usr/bin /usr/ccs/bin /usr/local/bin /usr/local /usr/local/netscape /usr/ucb \
            /bin /usr/5bin /usr/etc /usr/proc/bin /usr/X11R6/bin  /usr/lib /usr/lib64 \
            $MMSIMHOME/tools/bin \
            $MMSIMHOME/tools/spectre/bin \
            $MMSIMHOME/tools/ultrasim/bin \
            $MMSIMHOME/tools/relxpert/bin )

setenv LD_LIBRARY_PATH /usr/lib/X11:/usr/X11R6/lib:/usr/lib:/usr/dt/lib/usr/openwin/lib:/usr/ucblib

setenv LM_LICENSE_FILE 5280@localhost
setenv CDS_LIC_FILE $LM_LICENSE_FILE

setenv CDS_AUTO_64BIT ALL


setenv SPECTRE_REPORT_NUMBERS 1
setenv SPECTRE_TRANLOAD_DETAILS 1
setenv PRINT_LOAD_REPORT 1


echo "-----------------------DONE."
