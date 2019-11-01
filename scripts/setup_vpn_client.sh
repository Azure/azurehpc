#!/bin/bash

VPN_CLIENT_LIC_TAR_SAS_URL=$1
VPN_CLIENT_CONF=$2

if [[ $VPN_CLIENT_LIC_TAR_SAS_URL =~ .*\/(.+)\? ]]; then
   VPN_CLIENT_LIC_TAR=${BASH_REMATCH[1]}
   echo $VPN_CLIENT_LIC_TAR
fi 

yum install -y openvpn

pushd /tmp
wget -O $VPN_CLIENT_LIC_TAR "${VPN_CLIENT_LIC_TAR_SAS_URL}"
mkdir /tmp/lic
pushd lic
tar xvf ../$VPN_CLIENT_LIC_TAR

cp * /etc/openvpn/.
chmod 644 /etc/openvpn/*

systemctl enable openvpn@${VPN_CLIENT_CONF}
systemctl start openvpn@${VPN_CLIENT_CONF}

iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
sysctl -p

popd
rm $VPN_CLIENT_LIC_TAR
rm -rf lic
