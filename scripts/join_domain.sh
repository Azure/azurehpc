#!/bin/bash

ADMIN_DOMAIN=$1
ADMIN_NAME=$2
ADMIN_PASSWORD=$3
AD_SERVER=$4

echo $1 $2 $3 $4

yum install sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python -y

systemctl restart dbus
systemctl restart systemd-logind

NAMESERVER=`getent ahosts $AD_SERVER | awk '{print $1;exit}'`
echo "supersede domain-name-servers ${NAMESERVER};" > /etc/dhcp/dhclient.conf
echo "append domain-name-servers 168.63.129.16;" >> /etc/dhcp/dhclient.conf
systemctl restart NetworkManager

sleep 10

echo $ADMIN_PASSWORD| realm join -U $ADMIN_NAME $ADMIN_DOMAIN --verbose


sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

sed -i 's@override_homedir.*@override_homedir = /share/home/%u@' /etc/sssd/sssd.conf
sed -i 's@fallback_homedir.*@fallback_homedir = /share/home/%u@' /etc/sssd/sssd.conf
sed -i 's@use_fully_qualified_names.*@use_fully_qualified_names = False@' /etc/sssd/sssd.conf
sed -i 's@ldap_id_mapping.*@ldap_id_mapping = False@' /etc/sssd/sssd.conf
systemctl restart sssd

cat <<EOF >/etc/ssh/ssh_config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
