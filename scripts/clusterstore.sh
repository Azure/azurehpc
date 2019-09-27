#/bin/bash

CS_CLIENT_URL=$1

CS_CLIENT_ZIP=lustre-cray-2.11-int.B5.gf83bed.zip
CS_MOUNT_PT=/mnt/lustre
CS_CLIENT_VER=2.11 

KERNEL=$(uname -r)

yum groupinstall -y "Development Tools"
yum install -y kernel-devel-${KERNEL} zlib-devel libyaml-devel pdsh

cd /tmp
wget $CS_CLIENT_URL
unzip $CS_CLIENT_ZIP
sha1sum lustre-2.11.0.300_cray_63_gf83bed8-1.src.rpm; cat sha1sum.txt

rpmbuild --rebuild --without servers --without lustre-tests lustre-*.src.rpm
#yum install -y /root/rpmbuild/RPMS/x86_64/{kmod-lustre-client,lustre-client}-2.X.x86_64.rpm
rpm -ivh  /root/rpmbuild/RPMS/x86_64/{kmod-lustre-client,lustre-client}-${CS_CLIENT_VER}*.x86_64.rpm --nodeps

systemctl enable lnet
modprobe lnet
lctl network up
lctl list_nids

lnetctl net show --net tcp >> /etc/lnet.conf

echo "options lnet networks=tcp0(eth0)" >> /etc/modprobe.d/lnet.conf

mkdir $CS_MOUNT_PT
echo "mount -t lustre 172.30.10.14@tcp:172.30.10.15@tcp:/cls02022 $CS_MOUNT_PT" >> /etc/rc.d/rc.local
mount -t lustre 172.30.10.14@tcp:172.30.10.15@tcp:/cls02022 $CS_MOUNT_PT

df -h
