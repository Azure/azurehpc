#!/bin/bash

NHC_SYSCONFIG=/etc
OS_SYSCONFIG=/etc/default
NHC_TIMEOUT=300
NHC_VERBOSE=1
NHC_DETACHED_MODE=1
NHC_DEBUG=0
NHC_CONF_FILE_NEW=$CYCLECLOUD_SPEC_PATH/files/nd96asr_v4.conf
NHC_EXE=/usr/sbin/nhc
SLURM_CONF=/etc/slurm/slurm.conf
SLURM_HEALTH_CHECK_INTERVAL=300
SLURM_HEALTH_CHECK_NODE_STATE=IDLE
NHC_EXTRA_TEST_FILES="csc_nvidia_smi.nhc azure_cuda_bandwidth.nhc azure_gpu_app_clocks.nhc"


function nhc_config() {
   NHC_CONFIG_FILE=${NHC_SYSCONFIG}/nhc/nhc.conf
   if ! [[ -f ${NHC_CONFIG_FILE}_orig ]]
   then
      mv ${NHC_CONFIG_FILE} ${NHC_CONFIG_FILE}_orig
      cp ${NHC_CONF_FILE_NEW} ${NHC_CONFIG_FILE}
   else
      echo "Warning: Did not set up NHC config (Looks like it has already been set-up)"
   fi
}


function nhc_sysconfig() {
   NHC_SYSCONFIG_FILE=${OS_SYSCONFIG}/nhc
   if ! [[ -f ${NHC_SYSCONFIG_FILE} ]]
   then
      echo "TIMEOUT=$NHC_TIMEOUT" > $NHC_SYSCONFIG_FILE
      echo "VERBOSE=$NHC_VERBOSE" >> $NHC_SYSCONFIG_FILE
      echo "DETACHED_MODE=$NHC_DETACHED_MODE" >> $NHC_SYSCONFIG_FILE
      echo "DEBUG=$NHC_DEBUG" >> $NHC_SYSCONFIG_FILE
   else
      echo "Warning: Did not set up NHC sysconfig (Looks like it has already been set-up)"
   fi
}


function slurm_config() {
   
   grep HealthCheckProgram $SLURM_CONF | grep -q nhc
   if [[ $? -eq 1 ]]
   then
      echo "" >> $SLURM_CONF
      echo "HealthCheckProgram=${NHC_EXE}" >> $SLURM_CONF
      echo "HealthCheckInterval=${SLURM_HEALTH_CHECK_INTERVAL}" >> $SLURM_CONF
      echo "HealthCheckNodeState=${SLURM_HEALTH_CHECK_NODE_STATE}" >> $SLURM_CONF
   else
      echo "Warning: Did not configure SLURM to use NHC (Looks like it is already set-up)"
   fi 

}


function copy_extra_test_files() {

   for test_file in $NHC_EXTRA_TEST_FILES
   do
      chmod +x ${CYCLECLOUD_SPEC_PATH}/files/$test_file
      cp ${CYCLECLOUD_SPEC_PATH}/files/$test_file ${NHC_SYSCONFIG}/nhc/scripts
   done
}


mkdir /var/run/nhc
nhc_config
nhc_sysconfig
if [[ -z $CYCLECLOUD_HOME ]]; then
   slurm_config
fi
