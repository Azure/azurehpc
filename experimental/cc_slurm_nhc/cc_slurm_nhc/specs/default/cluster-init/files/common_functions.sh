# Set of common functions used across scripts

function is_slurm_controller() {
   test -e /usr/sbin/slurmctld
}
