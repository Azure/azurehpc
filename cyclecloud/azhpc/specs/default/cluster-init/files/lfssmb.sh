#!/bin/bash

yum install -y samba samba-client samba-common

cat <<EOF >/etc/samba/smb.conf
[global]
        workgroup = WORKGROUP
        server string = Samba Server %v
        security = user
        map to guest = bad user
        dns proxy = no

[lustre]
        path = /lustre
        browsable = yes
        writable = yes
        guest ok = yes
        read only = no
        force user = hpcuser
EOF
chmod 644 /etc/samba/smb.conf

systemctl enable smb
systemctl start smb

