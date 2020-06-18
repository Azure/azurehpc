#!/bin/bash
# Script to be run on all compute nodes
if rpm -q epel-release; then
    yum -y install epel-release
fi

if rpm -q git jq htop; then
    yum -y install git jq htop
fi

# change access to resource so that temp jobs can be written there
chmod 777 /mnt/resource

# If running on Cycle 
# - enable METADATA access
# - remove Jetpack convergence
# - Disable Fail2Ban service
# - Fix PBS limits
if [ -e /opt/cycle/jetpack/jetpack ]; then
    # Enable METADATA SERVICE access if blocked. This is the case with CycleCloud 7.x by default
    # Delete all rules regarding 169.254.169.254
    iptables -L
    rule=$(iptables -S | grep -E 169.254.169.254 | tail -n1)
    while [ -n "$rule" ]; do
        delete_rule=$(sed 's/-A/-D/g' <<< $(echo $rule))
        iptables $delete_rule
        rule=$(iptables -S | grep -E 169.254.169.254 | tail -n1)
    done
    iptables -L

    # Remove Jetpack converge from the crontab
    crontab -l | grep -v converge | crontab -

    # Disable fail2ban
    systemctl stop fail2ban
    systemctl disable fail2ban

    # Fix PBS limits issue
    if [ -e /opt/pbs/lib/init.d/limits.pbs_mom ]; then
        sed -i "s/^if /#if /g" /opt/pbs/lib/init.d/limits.pbs_mom
        sed -i "s/^fi/#fi /g" /opt/pbs/lib/init.d/limits.pbs_mom
    fi
fi
