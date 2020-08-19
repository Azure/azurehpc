#!/bin/bash

MASTER=$1

yum install -y readline-devel

git clone https://github.com/chaos/cerebro.git
cd cerebro
./autogen.sh
./configure
make
make install

cd ..
git clone https://github.com/LLNL/lmt.git
cd lmt
./autogen.sh
export LDFLAGS="-L//usr/local/lib"
./configure --disable-mysql
make
make install

cp /usr/local/etc/cerebro.conf /etc
sed -i 's#^ExecStart=.*#ExecStart=/usr/local/sbin/cerebrod#g' /usr/lib/systemd/system/cerebrod.service
mv /usr/local/lib/cerebro/cerebro_clusterlist_hostsfile.so /usr/local/lib/cerebro/cerebro_clusterlist_hostsfile.so_do_not_use

sed -i 's#^\# cerebrod_speak on#cerebrod_speak on#g' /etc/cerebro.conf
sed -i "s#^\# cerebrod_speak_message_config.*72#cerebrod_speak_message_config $MASTER#" /etc/cerebro.conf
if [ `hostname` == $MASTER ]; then
sed -i 's#^\# cerebrod_listen on#cerebrod_listen on#' /etc/cerebro.conf
sed -i "s#^\# cerebrod_listen_message_config.*0#cerebrod_listen_message_config $MASTER#" /etc/cerebro.conf
umount /mnt/mgsmds
ln -s /usr/local/bin/ltop /usr/bin/ltop
else
sed -i 's#^\# cerebrod_listen on#cerebrod_listen off#' /etc/cerebro.conf
fi
umount /mnt/oss

mount -a
if [ `hostname` == $MASTER ]; then
lctl set_param mdt.*-MDT0000.identity_upcall=NONE
fi

systemctl  daemon-reload
systemctl start cerebrod

