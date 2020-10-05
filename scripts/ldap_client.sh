#!/bin/bash

script_name=$(basename "$0")

function display_help {
    cat <<EOF
$script_name 

Set up the LDAP client.

Usage:
  $script_name --ldap-server HOST [--home-root HOME_DIR]

Options:
  -h, --help            Show this help message.
  --ldap-server HOST    The LDAP server
  --home-root HOME_DIR  The root for home directories.
                        [default: /share/home]
EOF
}

ldap_server=
home_root=/share/home

while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -h|--help)
            display_help
            exit 0
            ;;
        --ldap-server)
            ldap_server="$2"
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

if [ -z "$ldap_server" ]; then
    echo "ERROR: missing mandatory argument(s)"
    echo
    display_help
    exit 1
fi

ldap_base_dn="DC=${ldap_server},DC=local"

yum install -y openldap-clients nss-pam-ldapd sssd

# Configure Ldap
echo "URI ldap://$ldap_server" >> /etc/openldap/ldap.conf
echo "BASE $ldap_base_dn" >> /etc/openldap/ldap.conf

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
ldap_sudo_search_base = ou=Sudoers,$ldap_base_dn
ldap_uri = ldap://$ldap_server
ldap_id_use_start_tls = True
use_fully_qualified_names = False
ldap_tls_cacertdir = /etc/openldap/cacerts

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

echo | openssl s_client -connect $ldap_server:389 -starttls ldap > /root/open_ssl_ldap
mkdir /etc/openldap/cacerts
cat /root/open_ssl_ldap | openssl x509 >/etc/openldap/cacerts/openldap-server.pem

authconfig --disablesssd --disablesssdauth --disableldap --disableldapauth --disablekrb5 --disablekrb5kdcdns --disablekrb5realmdns --disablewinbind --disablewinbindauth --disablewinbindkrb5 --disableldaptls --disablerfc2307bis --updateall
sss_cache -E
authconfig --enablesssd --enablesssdauth --enableldap --enableldaptls --enableldapauth --ldapserver=ldap://$ldap_server --ldapbasedn=$ldap_base_dn --enablelocauthorize --enablemkhomedir --enablecachecreds --updateall

echo "sudoers: files sss" >> /etc/nsswitch.conf
