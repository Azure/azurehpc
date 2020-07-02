#!/bin/bash

# arg: $1 = lfsserver
# arg: $2 = mount point (default: /lustre)
master=$1
lfs_mount=${2:-/lustre}

cp -r /share/home/hpcuser/.ssh /root/

#Include the correct rdma options
cat >/etc/modprobe.d/lustre.conf<<EOF
options lnet networks=o2ib(ib0)
EOF

capture=$(ssh hpcuser@$master "sudo ip address show dev ib0")
masterib=$(echo $capture | awk -F 'inet' '{print $2}' | cut -d / -f 1 )
echo "masterib is $masterib"

if rpm -q lustre; then

    # if the server packages are installed only the client kmod is needed
    # for 2.10 and nothing extra is needed for 2.12
    if [ "$lustre_version" = "2.10" ]; then

        if ! rpm -q kmod-lustre-client; then
            yum -y install kmod-lustre-client
        fi

    fi

else

    # install the client RPMs if not already installed
    if ! rpm -q lustre-client kmod-lustre-client; then
        yum -y install lustre-client kmod-lustre-client
    fi
    weak-modules --add-kernel $(uname -r)

fi

#modprobe lnet
#modprobe lustre
sed -i 's/# OS.EnableRDMA=y/OS.EnableRDMA=y/g' /etc/waagent.conf
service waagent restart
service rdma start
modprobe lnet
lctl network configure
lnetctl net add --net o2ib --if ib0 #need this to come up every time
modprobe lustre
sleep 5



mkdir $lfs_mount
echo "${masterib}@o2ib:/LustreFS $lfs_mount lustre flock,defaults,_netdev 0 0" >> /etc/fstab
mount -a
chmod 777 $lfs_mount
