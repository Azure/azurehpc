# Set of common functions used across scripts

function is_slurm_controller() {
    ls /lib/systemd/system/ | grep -q slurmctld
}
