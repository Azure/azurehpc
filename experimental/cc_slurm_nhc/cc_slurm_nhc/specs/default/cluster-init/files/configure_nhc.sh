#!/bin/bash

NHC_SYSCONFIG=/etc
if [ -f /etc/centos-release ]; then
   OS_SYSCONFIG=/etc/sysconfig
else
   OS_SYSCONFIG=/etc/default
fi
NHC_TIMEOUT=300
NHC_VERBOSE=1
NHC_DETACHED_MODE=1
NHC_DEBUG=0
NHC_EXE=/usr/sbin/nhc
NHC_NVIDIA_HEALTHMON=dcgmi
NHC_NVIDIA_HEALTHMON_ARGS="diag -r 1"
SLURM_CONF=/sched/slurm.conf
SLURM_HEALTH_CHECK_INTERVAL=7200
SLURM_HEALTH_CHECK_NODE_STATE=IDLE
NHC_PROLOG=1
NHC_EPILOG=0
NHC_EXTRA_TEST_FILES="csc_nvidia_smi.nhc azure_cuda_bandwidth.nhc azure_gpu_app_clocks.nhc azure_gpu_ecc.nhc azure_gpu_persistence.nhc azure_ib_write_bw_gdr.nhc azure_nccl_allreduce_ib_loopback.nhc azure_ib_link_flapping.nhc azure_gpu_clock_throttling.nhc azure_cpu_drop_cache_mem.nhc azure_gpu_xid.nhc azure_nccl_allreduce.nhc"

source $CYCLECLOUD_SPEC_PATH/files/common_functions.sh

function select_sku_conf() {
   vm_size=`jetpack config azure.metadata.compute.vmSize | tr '[:upper:]' '[:lower:]'`
   case $vm_size in
        standard_nd96asr_v4)
           NHC_CONF_FILE_NEW=$CYCLECLOUD_SPEC_PATH/files/nd96asr_v4.conf
           ;;
        standard_nd96amsr_a100_v4)
           NHC_CONF_FILE_NEW=$CYCLECLOUD_SPEC_PATH/files/nd96amsr_v4.conf
           ;;
        standard_hb120-96rs_v3)
           NHC_CONF_FILE_NEW=$CYCLECLOUD_SPEC_PATH/files/hb120-96rs_v3.conf
           ;;
        standard_hb120-64rs_v3)
           NHC_CONF_FILE_NEW=$CYCLECLOUD_SPEC_PATH/files/hb120-64rs_v3.conf
           ;;
        standard_hb120-32rs_v3)
           NHC_CONF_FILE_NEW=$CYCLECLOUD_SPEC_PATH/files/hb120-32rs_v3.conf
           ;;
        standard_hb120-16rs_v3)
           NHC_CONF_FILE_NEW=$CYCLECLOUD_SPEC_PATH/files/hb120-16rs_v3.conf
           ;;
        standard_hb120rs_v3)
           NHC_CONF_FILE_NEW=$CYCLECLOUD_SPEC_PATH/files/hb120rs_v3.conf
           ;;
        *)
           echo "Error: $vm_size is currently not supported in NHC"
           exit 1
   esac
}

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
      echo "NVIDIA_HEALTHMON=$NHC_NVIDIA_HEALTHMON" >> $NHC_SYSCONFIG_FILE
      echo "NVIDIA_HEALTHMON_ARGS=\"$NHC_NVIDIA_HEALTHMON_ARGS\"" >> $NHC_SYSCONFIG_FILE
   else
      echo "Warning: Did not set up NHC sysconfig (Looks like it has already been set-up)"
   fi
}


function update_slurm_prolog_epilog() {

   prolog_epilog=$1
   script=$2
   grep -qi /sched/scripts/${prolog_epilog}.sh $SLURM_CONF
   prolog_epilog_does_not_exist=$?
   cp $CYCLECLOUD_SPEC_PATH/files/$script /sched/scripts
   chmod +x /sched/scripts/$script
   if [[ $prolog_epilog_does_not_exist == 1 ]]; then
      if [[ $prolog_epilog == "prolog" ]]; then
         cp $CYCLECLOUD_SPEC_PATH/files/prolog.sh /sched/scripts
         chmod +x /sched/scripts/prolog.sh
         echo "Prolog=/sched/prolog.sh" >> $SLURM_CONF
         echo "PrologFlags=Alloc" >> $SLURM_CONF
      elif [[ $prolog_epilog == "epilog" ]]; then
         cp $CYCLECLOUD_SPEC_PATH/files/epilog.sh /sched/scripts
         chmod +x /sched/scripts/epilog.sh
         echo "Epilog=/sched/scripts/epilog.sh" >> $SLURM_CONF
      fi
   else
      echo "/sched/scripts/$script" >> /sched/script/${prolog_epilog}.sh
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

      if [[ $NHC_PROLOG == 1 ]]; then
         update_slurm_prolog_epilog prolog kill_nhc.sh
      fi
      if [[ $NHC_EPILOG == 1 ]]; then
         update_slurm_prolog_epilog epilog run_nhc.sh
      fi
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

if is_slurm_controller; then
   slurm_config
else
   mkdir /var/run/nhc
   select_sku_conf
   nhc_config
   nhc_sysconfig
   copy_extra_test_files
fi
