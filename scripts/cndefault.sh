#!/bin/bash
if rpm -q epel-release; then
    yum -y install epel-release
fi

if rpm -q git jq htop; then
    yum -y install git jq htop
fi

# change access to resource so that temp jobs can be written there
chmod 777 /mnt/resource

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
