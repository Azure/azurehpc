#!/bin/bash
# arg: $1 = pbs_server
pbs_server=$1
version=${2-19}

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/azhpc-library.sh" # Needed to use the retry function
$script_dir/pbsdownload.sh $version

case "$version" in
    19)
        rpm_list="pbspro_19.1.3.centos_7/pbspro-execution-19.1.3-0.x86_64.rpm"
        rpm="pbspro-execution"
        SERVER_NAME_SUBST="CHANGE_THIS_TO_PBS_PRO_SERVER_HOSTNAME"
    ;;
    20)
        rpm_list="openpbs_20.0.1.centos_8/openpbs-execution-20.0.1-0.x86_64.rpm"
        rpm="openpbs-execution"
        SERVER_NAME_SUBST="CHANGE_THIS_TO_PBS_SERVER_HOSTNAME"
    ;;
    *)
        echo "Unknown version $version provided"
        echo "Usage : $0 <pbs_server> {19|20}"
        exit 1
    ;;    
esac

if ! rpm -q $rpm; then
    if ! rpm -q jq; then
        yum install -y jq
    fi

    yum install -y $rpm_list

    sed -i "s/${SERVER_NAME_SUBST}/${pbs_server}/g" /etc/pbs.conf
    sed -i "s/${SERVER_NAME_SUBST}/${pbs_server}/g" /var/spool/pbs/mom_priv/config
    sed -i "s/^if /#if /g" /opt/pbs/lib/init.d/limits.pbs_mom
    sed -i "s/^fi/#fi /g" /opt/pbs/lib/init.d/limits.pbs_mom
    systemctl enable pbs
    systemctl start pbs

    # Retrieve the VMSS name to be used as the pool name for multiple VMSS support
    poolName=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmScaleSetName')
    if [ -z "$poolName" ]; then
        echo "Unable to query MDS"
        poolName="compute"
    fi
    echo "Registering node for poolName $poolName"
    retry /opt/pbs/bin/qmgr -c "c n $(hostname) resources_available.pool_name='$poolName'"
else
    echo "PBS client was already installed"
fi
