#!/bin/ash

user=$1
key="$2"
shift
shift

echo "user = $user"
echo "key  = $key"

# generate host keys if not present
ssh-keygen -A

# disable root access
passwd -d root

# add user
adduser -D -s /bin/bash $user
passwd -u $user
mkdir /home/$user/.ssh
cat <<EOF >/home/$user/.ssh/authorized_keys
$key
EOF
chown -R $user:$user /home/$user
chmod 700 /home/$user/.ssh
chmod 600 /home/$user/.ssh/authorized_keys

# do not detach (-D), log to stderr (-e)
exec /usr/sbin/sshd -D -e "$@"
