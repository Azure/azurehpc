#!/bin/bash

function set_detached_mode() {
   TARGET_MODE=$1
   sudo sed -i "s/DETACHED_MODE.*/DETACHED_MODE=${TARGET_MODE}/g" /etc/default/nhc
}

set_detached_mode 0
sudo /usr/sbin/nhc
NHC_RC=$?
set_detached_mode 1

exit ${NHC_RC}
