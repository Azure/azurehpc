#/bin/bash
BEEGFS_MOUNT=${1-/beegfs}

beegfs-df -p $BEEGFS_MOUNT
beegfs-check-servers
