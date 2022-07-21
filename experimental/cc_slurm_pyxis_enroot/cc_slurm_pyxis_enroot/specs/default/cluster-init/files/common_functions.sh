# Set of common functions used across scripts

function is_slurm_controller() {
   systemctl list-units --full -all | grep -q slurmctld
}
