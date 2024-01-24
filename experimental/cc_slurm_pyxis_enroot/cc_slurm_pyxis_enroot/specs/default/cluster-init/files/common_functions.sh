# Set of common functions used across scripts

function is_slurm_controller() {
    ls /lib/systemd/system/ | grep -q slurmctld
}

function is_login_node() {
    ! (ls /lib/systemd/system/ | grep -q slurm)
}

function is_compute_node() {
	! is_slurm_controller && ! is_login_node
}
