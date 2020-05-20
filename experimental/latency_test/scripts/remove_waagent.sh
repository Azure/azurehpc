#!/bin/bash

echo "sleeping for 90 seconds"
sleep 90
systemctl stop waagent
sleep 5
systemctl status waagent

# exit cleanly as waagent returns error code if the agent is not running
exit 0
