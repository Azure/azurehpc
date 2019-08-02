#!/bin/bash
DOWNLOAD_DIR=/mnt/resource

# setup IX
ECLPATH=/apps/ecl
SHARED_APP=/apps
APP_NAME=ecl
APP_VERSION=2018.2
PACKAGE=${APP_VERSION}_IX_DVD.iso
PACKAGE2=${APP_VERSION}_DVD.iso
MODULE_DIR=${SHARED_APP}/modulefiles
MODULE_NAME=intersect_${APP_VERSION}

#NOTE!!! Populate these variables before running the script
LICENSE_PORT_IP=<PORT@IP for license server>
IX_ISO_SAS_URL=/path/to/intersect_iso.tar
ECLIPSE_ISO_SAS_URL=/path/to/eclipse_iso.tar

function create_intersect_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module 1.0
#
#  intersect module for use with 'environment-modules' package:
#
prepend-path            PATH                   ${SHARED_APP}/${APP_NAME}/tools/linux_x86_64/eclpython/bin
prepend-path            PATH                   ${SHARED_APP}/${APP_NAME}/macros
setenv                  LM_LICENSE_FILE        ${LICENSE_PORT_IP}
setenv                  F_UFMTENDIAN           big
EOF
}

if [ ! -f ${DOWNLOAD_DIR}/${PACKAGE2} ]; then
wget "${ECLIPSE_ISO_SAS_URL}" -O ${DOWNLOAD_DIR}/${PACKAGE2}
fi

sudo mkdir /mnt/iso2
sudo mount -t iso9660 -o loop ${DOWNLOAD_DIR}/${PACKAGE2} /mnt/iso2

csh /mnt/iso2/ECLIPSE/UNIX/install/cdinst.csh <<EOF
2
A
${SHARED_APP}/${APP_NAME}
y
EOF

if [ ! -f ${DOWNLOAD_DIR}/${PACKAGE} ]; then
wget "${IX_ISO_SAS_URL}" -O ${DOWNLOAD_DIR}/${PACKAGE}
fi

sudo mkdir /mnt/iso
sudo mount -t iso9660 -o loop ${DOWNLOAD_DIR}/${PACKAGE} /mnt/iso

csh /mnt/iso/UNIX/install/cdinst.csh <<EOF
A
${SHARED_APP}/${APP_NAME}
y
EOF

create_intersect_modulefile

sudo sed -i 's/\/opt\/intel\/compilers_and_libraries_2018.1.163\/linux\/mpi/\/apps\/ecl\/tools\/linux_x86_64\/intel\/mpi\/2018.1.163/g' ${ECLPATH}/tools/linux_x86_64/intel/mpi/2018.1.163/intel64/bin/mpivars.sh
