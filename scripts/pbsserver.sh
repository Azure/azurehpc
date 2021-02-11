#!/bin/bash
version=${1-19}
set -e
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$script_dir/azhpc-library.sh" # Needed to use the retry function
$script_dir/pbsdownload.sh $version

case "$version" in
    19)
        rpm_list="pbspro_19.1.3.centos_7/pbspro-server-19.1.3-0.x86_64.rpm"
        rpm="pbspro-server"
    ;;
    20)
        rpm_list="openpbs_20.0.1.centos_8/openpbs-server-20.0.1-0.x86_64.rpm"
        rpm="openpbs-server"
    ;;
    *)
        echo "Unknown version $version provided"
        echo "Usage : $0 {19|20}"
        exit 1
    ;;    
esac

admin_user=$(whoami)

if [ "$(rpm -qa $rpm)" = "" ];then
    yum install -y $rpm_list
    systemctl enable pbs
    systemctl start pbs
    retry /opt/pbs/bin/qmgr -c "s s managers += ${admin_user}@*"
    retry /opt/pbs/bin/qmgr -c 's s flatuid=t'
    retry /opt/pbs/bin/qmgr -c 's s job_history_enable=t'
    retry /opt/pbs/bin/qmgr -c 'c r pool_name type=string,flag=h'

    # Update the sched_config file to schedule jobs that request pool_name
    sed -i "s/^resources: \"ncpus,/resources: \"ncpus, pool_name,/g" /var/spool/pbs/sched_priv/sched_config
    systemctl restart pbs
else
    echo "PBSPro already installed"
fi
