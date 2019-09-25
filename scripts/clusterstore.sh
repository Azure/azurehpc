#/bin/bash

CS_CLIENT_URL=$1

CS_CLIENT_ZIP=lustre-cray-2.11-int.B5.gf83bed.zip
KERNEL=$(uname -r)

yum groupinstall -y "Development Tools"
yum install -y kernel-devel-${KERNEL} zlib-devel libyaml-devel pdsh

cd /tmp
wget -O $CS_CLIENT_ZIP $CS_CLIENT_URL

rpmbuild --rebuild --without servers --without lustre-tests lustre-*.src.rpm
rpm -ivh  /root/rpmbuild/RPMS/x86_64/{kmod-lustre-client,lustre-client}-2.X.x86_64.rpm --nodeps

systemctl enable lnet
modprobe lnet
lctl network up
lctl list_nids

lnetctl net show --net tcp >> /etc/lnet.conf

echo "options lnet networks=tcp0(eth0)" >> /etc/modprobe.d/lnet.conf

mkdir /mnt/lustre
echo "mount -t lustre 172.30.10.14@tcp:172.30.10.15@tcp:/cls02022 /mnt/lustre" >> /etc/rc.d/rc.local
mount -t lustre 172.30.10.14@tcp:172.30.10.15@tcp:/cls02022 /mnt/lustre

df -h
