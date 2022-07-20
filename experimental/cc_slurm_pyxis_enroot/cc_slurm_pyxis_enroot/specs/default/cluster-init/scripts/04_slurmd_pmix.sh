#!/bin/bash
chmod +x $CYCLECLOUD_SPEC_PATH/files/*.sh
$CYCLECLOUD_SPEC_PATH/files/slurmd_pmix.sh &
