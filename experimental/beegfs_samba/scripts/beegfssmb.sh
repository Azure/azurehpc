#!/bin/bash

yum install -y samba samba-client samba-common

cat <<EOF >/etc/samba/smb.conf
[global]
        workgroup = WORKGROUP
        server string = Samba Server %v
        security = user
        map to guest = bad user
        dns proxy = no
        server multi channel support = yes
        aio read size = 1
        aio write size = 1
        kernel share modes = no
        kernel oplocks = no
        map archive = no
        map hidden = no
        map read only = no
        map system = no
        store dos attributes = yes
        socket options = TCP_NODELAY

[beegfs]
        path = /beegfs
        browsable = yes
        writable = yes
        guest ok = yes
        read only = no
        force user = hpcadmin
EOF
chmod 644 /etc/samba/smb.conf

systemctl enable smb
systemctl start smb

