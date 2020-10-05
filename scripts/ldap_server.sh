#!/bin/bash

script_name=$(basename "$0")

function display_help {
    cat <<EOF
$script_name 

Set up the LDAP server.

Usage:
  $script_name [--home-root HOME_DIR] [--ldap-admin LDAP_ADMIN]
               [--ldap-password-file LDAP_PASSWORD_FILE]

Options:
  -h, --help            Show this help message.
  --ldap-admin LDAP_ADMIN
                        The LDAP admin username
                        [default: admin]
  --ldap-password-file LDAP_PASSWORD_FILE
                        A file location to write the LDAP admin password
                        [default: /root/ldap_admin_password.txt]
  --home-root HOME_DIR  The root for home directories.
                        [default: /share/home]
EOF
}

home_root=/share/home
ldap_admin_username=admin
ldap_admin_password_file=/root/ldap_admin_password.txt

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
        *)    
            # unknown option
            echo "ERROR: unknown option - $1"
            echo
            display_help
            exit 1
            ;;
    esac
done

yum install -y openldap openldap-clients openldap-servers openldap-devel sssd

server_hostname=$HOSTNAME
ldap_base_dn="DC=${server_hostname},DC=local"
home_root=/share/home

systemctl enable slapd
systemctl start slapd

ldap_password=$(slappasswd -g)
echo -n "$ldap_password" >$ldap_admin_password_file
chmod 600 $ldap_admin_password_file
echo "URI ldap://$server_hostname" >>/etc/openldap/ldap.conf
echo "BASE $ldap_base_dn" >>/etc/openldap/ldap.conf

openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/CN=$server_hostname" \
    -keyout /etc/openldap/certs/${server_hostname}.key -out /etc/openldap/certs/${server_hostname}.crt
chown ldap:ldap /etc/openldap/certs/${server_hostname}.key /etc/openldap/certs/${server_hostname}.crt
chmod 600 /etc/openldap/certs/${server_hostname}.key /etc/openldap/certs/${server_hostname}.crt

cat <<EOF >ldap_db.ldif
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: $ldap_base_dn

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=${ldap_admin_username},$ldap_base_dn

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $(/sbin/slappasswd -h "{SSHA}" -s $ldap_password)
EOF

cat <<EOF >ldap_update_ssl_cert.ldif
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/${server_hostname}.crt
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/${server_hostname}.key
EOF

cat <<EOF >ldap_change_user_password.ldif
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to attrs=userPassword by self write by anonymous auth by group.exact="ou=admins,$ldap_base_dn" write by * none
-
add: olcAccess
olcAccess: {1}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" write by dn.base="ou=admins,$ldap_base_dn" write by * read
EOF

cat <<EOF >ldap_sudoers.ldif
dn: cn=sudo,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: sudo
olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.1 NAME 'sudoUser' DESC 'User(s) who may  run sudo' EQUALITY caseExactIA5Match SUBSTR caseExactIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.2 NAME 'sudoHost' DESC 'Host(s) who may run sudo' EQUALITY caseExactIA5Match SUBSTR caseExactIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.3 NAME 'sudoCommand' DESC 'Command(s) to be executed by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.4 NAME 'sudoRunAs' DESC 'User(s) impersonated by sudo (deprecated)' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.5 NAME 'sudoOption' DESC 'Options(s) followed by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.6 NAME 'sudoRunAsUser' DESC 'User(s) impersonated by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
olcAttributeTypes: ( 1.3.6.1.4.1.15953.9.1.7 NAME 'sudoRunAsGroup' DESC 'Group(s) impersonated by sudo' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
olcObjectClasses: ( 1.3.6.1.4.1.15953.9.2.1 NAME 'sudoRole' SUP top STRUCTURAL DESC 'Sudoer Entries' MUST ( cn ) MAY ( sudoUser $ sudoHost $ sudoCommand $ sudoRunAs $ sudoRunAsUser $ sudoRunAsGroup $ sudoOption $ description ) )
EOF

/bin/ldapmodify -Y EXTERNAL -H ldapi:/// -f ldap_db.ldif
/bin/ldapmodify -Y EXTERNAL -H ldapi:/// -f ldap_update_ssl_cert.ldif
/bin/ldapmodify -Y EXTERNAL -H ldapi:/// -f ldap_change_user_password.ldif
/bin/ldapadd -Y EXTERNAL -H ldapi:/// -f ldap_sudoers.ldif
/bin/ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
/bin/ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
/bin/ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

cat <<EOF >ldap_base.ldif
dn: $ldap_base_dn
dc: ${server_hostname}
objectClass: top
objectClass: domain

dn: cn=${ldap_admin_username},$ldap_base_dn
objectClass: organizationalRole
cn: ${ldap_admin_username}
description: LDAP Manager

dn: ou=People,$ldap_base_dn
objectClass: organizationalUnit
ou: People

dn: ou=Group,$ldap_base_dn
objectClass: organizationalUnit
ou: Group

dn: ou=Sudoers,$ldap_base_dn
objectClass: organizationalUnit

dn: ou=admins,$ldap_base_dn
objectClass: organizationalUnit
ou: Group
EOF

/bin/ldapadd -x -W -y $ldap_admin_password_file -D "cn=${ldap_admin_username},$ldap_base_dn" -f ldap_base.ldif

authconfig \
    --enablesssd \
    --enablesssdauth \
    --enableldap \
    --enableldapauth \
    --ldapserver="ldap://$server_hostname" \
    --ldapbasedn="$ldap_base_dn" \
    --enablelocauthorize \
    --enablemkhomedir \
    --enablecachecreds \
    --updateall

echo "sudoers: files sss" >> /etc/nsswitch.conf

# Configure SSSD
cat <<EOF >/etc/sssd/sssd.conf
[domain/default]
enumerate = True
autofs_provider = ldap
cache_credentials = True
ldap_search_base = $ldap_base_dn
id_provider = ldap
auth_provider = ldap
chpass_provider = ldap
sudo_provider = ldap
ldap_tls_cacert = /etc/openldap/certs/${server_hostname}.crt
ldap_sudo_search_base = ou=Sudoers,$ldap_base_dn
ldap_uri = ldap://$server_hostname
ldap_id_use_start_tls = True
use_fully_qualified_names = False
ldap_tls_cacertdir = /etc/openldap/certs/

[sssd]
services = nss, pam, autofs, sudo
full_name_format = %2\$s\%1\$s
domains = default

[nss]
homedir_substring = $home_root

[pam]

[sudo]
ldap_sudo_full_refresh_interval=86400
ldap_sudo_smart_refresh_interval=3600

[autofs]

[ssh]

[pac]

[ifp]

[secrets]
EOF
chmod 600 /etc/sssd/sssd.conf

systemctl enable sssd
systemctl restart sssd
