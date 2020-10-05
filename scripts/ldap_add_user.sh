#!/bin/bash

script_name=$(basename "$0")

server_hostname=$HOSTNAME
ldap_base_dn="DC=${server_hostname},DC=local"

function display_help {
    cat <<EOF
$script_name 

Add an LDAP user.

Usage:
  $script_name --username USERNAME --user-id USER_ID
               [--ldap-admin LDAP_ADMIN]
               [--ldap-password-file LDAP_PASSWORD_FILE]
               [--sudo] [--ssh-key SSH_KEY] [--home-root HOME_DIR]
               [--password PASSWORD] [--ssh-key SSH_KEY]

Options:
  -h, --help            Show this help message.
  --ldap-admin LDAP_ADMIN
                        The LDAP admin username
                        [default: admin]
  --ldap-password-file LDAP_PASSWORD_FILE
                        A file containing the LDAP admin password
                        [default: /root/ldap_admin_password.txt]
  --home-root HOME_DIR  The root for home directories.
                        [default: /share/home]
  --username USERNAME   The users name to add
  --password PASSWORD   The users password (empty means random string)
                        [default: <empty-string>]
  --user-id  USER_ID    The UID (also used for GID) to use
  --ssh-key SSH_KEY     An additional public key to add to authorized_keys
  --sudo                Give user sudo privilidges
EOF
}

password=
ldap_admin_username=admin
ldap_admin_password_file=/root/ldap_admin_password.txt
home_root=/share/home
username=
password=$(slappasswd -g)
user_id=
add_sudo=
ssh_key=

while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -h|--help)
            display_help
            exit 0
            ;;
        --ldap-admin)
            ldap_admin_username="$2"
            shift 2
            ;;
        --ldap-password-file)
            ldap_admin_password_file="$2"
            shift 2
            ;;
        --home-root)
            home_root="$2"
            shift 2
            ;;
        --username)
            username="$2"
            shift 2
            ;;
        --password)
            password="$2"
            shift 2
            ;;
        --user-id)
            user_id="$2"
            shift 2
            ;;
        --ssh-key)
            ssh_key="$2"
            shift 2
            ;;
        --sudo)
            add_sudo=yes
            shift
            ;;
        *)    
            # unknown option
            echo "ERROR: unknown option - $1"
            echo
            display_help
            exit 1
            ;;
    esac
done

if [ -z "$username" -o -z "$user_id" ]; then
    echo "ERROR: missing mandatory argument(s)"
    echo
    display_help
    exit 1
fi

user_ldif="ldap_user_${username}.ldif"
cat <<EOF >$user_ldif
dn: uid=${username},ou=People,${ldap_base_dn}
objectClass: top
objectClass: person
objectClass: posixAccount
objectClass: shadowAccount
objectClass: inetOrgPerson
objectClass: organizationalPerson
cn: $username
sn: $username
uid: $username
uidNumber: $user_id
gidNumber: $user_id
loginShell: /bin/bash
homeDirectory: ${home_root}/${username}
userPassword: $(/sbin/slappasswd -h "{SSHA}" -s $password)
EOF

ldapadd -x -W -y $ldap_admin_password_file -D "cn=${ldap_admin_username},$ldap_base_dn" -f $user_ldif

group_ldif="ldap_group_${username}.ldif"
cat <<EOF >$group_ldif
dn: cn=${username},ou=group,${ldap_base_dn}
objectClass: top
objectClass: posixGroup
gidNumber: $user_id
cn: $username
EOF

ldapadd -x -W -y $ldap_admin_password_file -D "cn=${ldap_admin_username},$ldap_base_dn" -f $group_ldif

if [ "$add_sudo" != "" ]; then

    sudo_ldif="ldap_sudo_${username}.ldif"
    cat <<EOF >$sudo_ldif
dn: cn=${username},ou=Sudoers,${ldap_base_dn}
objectClass: top
objectClass: sudoRole
sudoHost: ALL
sudoUser: $username
sudoCommand: ALL
sudoOption: !authenticate
EOF

    ldapadd -x -W -y $ldap_admin_password_file -D "cn=${ldap_admin_username},$ldap_base_dn" -f $sudo_ldif

fi

if [ ! -d $home_root/$username ]; then

    mkdir -p $home_root/$username
    chown $username:$username $home_root/$username
    chmod 750 $home_root/$username

    cp /etc/skel/.bashrc $home_root/$username
    cp /etc/skel/.bash_profile $home_root/$username
    cp /etc/skel/.bash_logout $home_root/$username
    chown $username:$username $home_root/$username/.bashrc
    chown $username:$username $home_root/$username/.bash_profile
    chown $username:$username $home_root/$username/.bash_logout

    mkdir $home_root/$username/.ssh
    cat <<EOF >$home_root/$username/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF

    ssh-keygen -f $home_root/$username/.ssh/id_rsa -t rsa -N ''
    if [ "$ssh_key" != "" ]; then
        echo "$ssh_key" >$home_root/$username/.ssh/authorized_keys
    fi
    cat $home_root/$username/.ssh/id_rsa.pub >>$home_root/$username/.ssh/authorized_keys
    chown $username:$username $home_root/$username/.ssh
    chown $username:$username $home_root/$username/.ssh/*
    chmod 700 $home_root/$username/.ssh
    chmod 600 $home_root/$username/.ssh/id_rsa
    chmod 644 $home_root/$username/.ssh/id_rsa.pub
    chmod 644 $home_root/$username/.ssh/config
    chmod 644 $home_root/$username/.ssh/authorized_keys

fi
