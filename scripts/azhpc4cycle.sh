#!/bin/bash
# This utility script contains helpers functions called in the azurehpc to CycleCloud integration
helper=${1,,}
JETPACK_HOME=/opt/cycle/jetpack

if [ ! -e $JETPACK_HOME/bin/jetpack ]; then
    echo "Not running in a CycleCloud environment exiting"
else
    echo "Running in a CycleCloud environment"
fi

enable_metada_access()
{
    # Enable METADATA SERVICE access if blocked. This is the case with CycleCloud 7.x by default
    # Delete all rules regarding 169.254.169.254
    prevent_metadata_access=$($JETPACK_HOME/bin/jetpack config cyclecloud.node.prevent_metadata_access)
    echo "cyclecloud.node.prevent_metadata_access=$prevent_metadata_access"
    echo "Allow Metadata Service access"
    echo "Dumping IPTABLES"
    iptables -L
    rule=$(iptables -S | grep -E 169.254.169.254 | tail -n1)
    while [ -n "$rule" ]; do
        delete_rule=$(sed 's/-A/-D/g' <<< $(echo $rule))
        iptables $delete_rule
        rule=$(iptables -S | grep -E 169.254.169.254 | tail -n1)
    done
    echo "Dumping IPTABLES"
    iptables -L
}

# Disabling jetpack converge can only be done thru a cron as cluster-init scripts are executed before the crontab is updated with the converge entry
# If converge is enabled, add a cron to run every minute until the converge entry in the crontab is removed
disable_jetpack_converge()
{
    # Remove Jetpack converge from the crontab
    maintenance_converge=$($JETPACK_HOME/bin/jetpack config cyclecloud.maintenance_converge.enabled)
    maintenance_converge=${maintenance_converge,,}
    echo "cyclecloud.maintenance_converge.enabled=$maintenance_converge"
    if [ "$maintenance_converge" == "true" ]; then
        # Check if converge is in the crontab and if so remove it, if not add a cron entry to check it every minute
        grep_for="jetpack converge --mode=maintenance"
        converge=$(crontab -l | grep "$grep_for")
        if [ -n "$converge" ]; then
            echo "Dump crontab"
            crontab -l
            echo "Remove Jetpack converge from crontab"
            crontab -l | grep -v "$grep_for" | crontab -
            echo "Remove our crontab entry"
            crontab -l | grep -v "disable_jetpack_converge" | crontab -
            echo "Dump crontab"
            crontab -l
        else
            echo "*/1 * * * * $0 disable_jetpack_converge >> $JETPACK_HOME/logs/azhpc4cycle.log 2>&1" > crontab-fragment.txt
            crontab -l | cat - crontab-fragment.txt >crontab.txt 
            crontab crontab.txt
        fi
    fi
}

disable_fail2ban()
{
    # Disable fail2ban
    echo "Disabling fail2ban"
    systemctl stop fail2ban
    systemctl disable fail2ban
}

fix_pbs_limits()
{
    # Fix PBS limits issue
    if [ -e /opt/pbs/lib/init.d/limits.pbs_mom ]; then
        echo "Fixing limits.pbs_mom"
        sed -i "s/^if /#if /g" /opt/pbs/lib/init.d/limits.pbs_mom
        sed -i "s/^fi/#fi /g" /opt/pbs/lib/init.d/limits.pbs_mom
    fi
}

case $helper in
    enable_metada_access)
        enable_metada_access
        ;;
    disable_jetpack_converge)
        disable_jetpack_converge
        ;;
    disable_fail2ban)
        disable_fail2ban
        ;;
    fix_pbs_limits)
        fix_pbs_limits
        ;;
    *)
        echo "unknown function"
        ;;
esac