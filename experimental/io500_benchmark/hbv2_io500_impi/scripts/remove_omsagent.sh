#!/bin/bash

# Remove agent only if installed
if [ -e /opt/microsoft/omsagent/bin/omsadmin.sh ]; then
    wget -q https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh && sh onboard_agent.sh --purge
fi
