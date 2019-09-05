#!/bin/bash

ADMIN_DOMAIN=$1
ADMIN_NAME=$2
ADMIN_PASSWORD=$3

echo $1 $2 $3

yum install sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python -y

systemctl restart dbus
systemctl restart systemd-logind

#NAMESERVER=$(jetpack config adjoin.ad.dns1)
NAMESERVER=10.2.1.4
if [ ! -f /etc/resolv.conf.bak ]; then
    cp /etc/resolv.conf /etc/resolv.conf.bak
fi
if grep -q "nameserver $NAMESERVER" /etc/resolv.conf ; then
    echo "resolv.conf already changed"
else
    echo "nameserver $NAMESERVER" >> /etc/resolv.conf.tmp
    cat /etc/resolv.conf >> /etc/resolv.conf.tmp
    mv /etc/resolv.conf.tmp /etc/resolv.conf
fi

#ADMIN_DOMAIN=$(jetpack config adjoin.ad.domain)
#ADMIN_DOMAIN=MyDomain.local
#ADMIN_NAME=$(jetpack config adjoin.ad.admin.name)
#ADMIN_NAME=hpcadmin
#ADMIN_PASSWORD=$(jetpack config adjoin.ad.admin.password)
#ADMIN_PASSWORD=admin_1234567
echo $ADMIN_PASSWORD| realm join -U $ADMIN_NAME $ADMIN_DOMAIN --verbose


sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
service sshd restart


sed -i 's@override_homedir.*@override_homedir = /share/home/%u@' /etc/sssd/sssd.conf
sed -i 's@fallback_homedir.*@fallback_homedir = /share/home/%u@' /etc/sssd/sssd.conf
sed -i 's@use_fully_qualified_names.*@use_fully_qualified_names = False@' /etc/sssd/sssd.conf
service sssd restart


