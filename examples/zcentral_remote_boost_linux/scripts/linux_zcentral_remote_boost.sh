#!/bin/bash

ZCENTRAL_SENDER_SAS_URL=$1
ZCENTRAL_SENDER_LICENSE_SAS_URL=$2
LINUX_VERSION=${3:-rhel7-8}

function get_sas_url_filename() {
   url_path=${1%\?*}
   eval $2=$(basename $url_path)
}

function install_zcentral_sender() {
   wget -O $SENDER_TAR_GZ $ZCENTRAL_SENDER_SAS_URL
   tar xvf $SENDER_TAR_GZ
   cd ${LINUX_VERSION}/sender
   chmod 777 ./install.sh
   ./install.sh -acceptLicense -noflex
}

get_sas_url_filename $ZCENTRAL_SENDER_SAS_URL SENDER_TAR_GZ
echo $SENDER_TAR_GZ
get_sas_url_filename $ZCENTRAL_SENDER_LICENSE_SAS_URL LICENSE_FILE

install_zcentral_sender

cd /etc/opt/hpremote/rgsender
wget -O $LICENSE_FILE $ZCENTRAL_SENDER_LICENSE_SAS_URL
