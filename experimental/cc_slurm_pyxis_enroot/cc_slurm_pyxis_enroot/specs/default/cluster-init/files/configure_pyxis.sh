#!/bin/bash

source $CYCLECLOUD_SPEC_PATH/files/common_functions.sh

function link_plugstack() {
   ln -s /sched/plugstack.conf /etc/slurm/plugstack.conf
   ln -s /sched/plugstack.conf.d /etc/slurm/plugstack.conf.d
}

function install_plugstack() {
   mkdir -p /sched/plugstack.conf.d
   echo 'include /sched/plugstack.conf.d/*' > /sched/plugstack.conf
   chown -R slurm:slurm /sched/plugstack.conf
   echo 'required /usr/lib64/slurm/spank_pyxis.so' > /sched/plugstack.conf.d/pyxis.conf
   chown slurm:slurm /sched/plugstack.conf.d/pyxis.conf
   link_plugstack
}

function install_prolog() {
   mkdir -p /sched/scripts
   cp ${CYCLECLOUD_SPEC_PATH}/files/prolog.sh /sched/scripts/prolog.sh
   chown slurm:slurm /sched/scripts/prolog.sh
   chmod 755 /sched/scripts/prolog.sh
   echo 'Prolog=/sched/scripts/prolog.sh' >> /sched/slurm.conf
   echo 'PrologFlags=Alloc' >> /sched/slurm.conf
}

if is_slurm_controller; then
   install_plugstack
   install_prolog
   systemctl restart slurmctld
else
   link_plugstack
   systemctl restart slurmd
fi

