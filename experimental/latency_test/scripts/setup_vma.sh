wget "http://content.mellanox.com/ofed/MLNX_OFED-5.0-2.1.8.0/MLNX_OFED_LINUX-5.0-2.1.8.0-rhel7.6-x86_64.tgz"
tar zxvf MLNX_OFED_LINUX-5.0-2.1.8.0-rhel7.6-x86_64.tgz
cd MLNX_OFED_LINUX-5.0-2.1.8.0-rhel7.6-x86_64
yum install -y http://olcentgbl.trafficmanager.net/centos/7.6.1810/updates/x86_64/kernel-devel-3.10.0-957.27.2.el7.x86_64.rpm
yum install -y python-devel redhat-rpm-config rpm-build gcc tcl tk
./mlnxofedinstall --guest --vma --skip-repo --add-kernel-support
/etc/init.d/openibd restart

echo "kernel.shmmax = 1000000000" | tee -a /etc/sysctl.conf
echo "vm.nr_hugepages = 800" | tee -a /etc/sysctl.conf
sysctl -p

vmad
