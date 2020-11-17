#!/usr/bin/python
# Prepare an Azure provider account for CycleCloud usage.
import os
import argparse
import tarfile
import json
import re
import random
from string import ascii_letters, ascii_uppercase, ascii_lowercase, digits
from subprocess import CalledProcessError, check_output
from os import path, listdir, makedirs, chdir, fdopen, remove
from urllib2 import urlopen, Request, HTTPError, URLError
from urllib import urlretrieve
from shutil import rmtree, copy2, move, copytree
from tempfile import mkstemp, mkdtemp
from time import sleep


tmpdir = mkdtemp()
print "Creating temp directory " + tmpdir + " for installing CycleCloud"
cycle_root = "/opt/cycle_server"
cs_cmd = cycle_root + "/cycle_server"


def clean_up():
    rmtree(tmpdir)

def _catch_sys_error(cmd_list):
    try:
        output = check_output(cmd_list)
        print cmd_list
        print output
        return output
    except CalledProcessError as e:
        print "Error with cmd: %s" % e.cmd
        print "Output: %s" % e.output
        raise

def create_user(username):
    import pwd
    try:
        pwd.getpwnam(username)
    except KeyError:
        print('Creating user ' + username)    
        _catch_sys_error(["useradd", "-m", "-d", "/home/" + username, username])
    _catch_sys_error(["chown", "-R", username + ":" + username, "/home/" + username])

def create_keypair(username, public_key=None):
    if not os.path.isdir("/home/" + username + "/.ssh"):
        _catch_sys_error(["mkdir", "-p", "/home/" + username + "/.ssh"])
    public_key_file  = "/home/" + username + "/.ssh/id_rsa.pub"
    if not os.path.exists(public_key_file):
        if public_key:
            with open(public_key_file, 'w') as pubkeyfile:
                pubkeyfile.write(public_key)
                pubkeyfile.write("\n")
        else:
            _catch_sys_error(["ssh-keygen", "-f", "/home/" + username + "/.ssh/id_rsa", "-N", ""])
            with open(public_key_file, 'r') as pubkeyfile:
                public_key = pubkeyfile.read()

    authorized_key_file = "/home/" + username + "/.ssh/authorized_keys"
    authorized_keys = ""
    if os.path.exists(authorized_key_file):
        with open(authorized_key_file, 'r') as authkeyfile:
            authorized_keys = authkeyfile.read()
    if public_key not in authorized_keys:
        with open(authorized_key_file, 'w') as authkeyfile:
            authkeyfile.write(public_key)
            authkeyfile.write("\n")
    _catch_sys_error(["chown", "-R", username + ":" + username, "/home/" + username])
    return public_key

def create_user_credential(username, public_key=None):
    create_user(username)    
    public_key = create_keypair(username, public_key)

    credential_record = {
        "PublicKey": public_key,
        "AdType": "Credential",
        "CredentialType": "PublicKey",
        "Name": username + "/public"
    }
    credential_data_file = tmpdir + "/credential.json"
    with open(credential_data_file, 'w') as fp:
        json.dump(credential_record, fp)

    copy2(credential_data_file, cycle_root + "/config/data/")

def cyclecloud_account_setup(vm_metadata, use_managed_identity, tenant_id, application_id, application_secret,
                             admin_user, azure_cloud, accept_terms, password, storageAccount):

    print "Setting up azure account in CycleCloud and initializing cyclecloud CLI"    

    if not accept_terms:
        print "Accept terms was FALSE !!!!!  Over-riding for now..."
        accept_terms = True

    # if path.isfile(cycle_root + "/config/data/account_data.json.imported"):
    #     print 'Azure account is already configured in CycleCloud. Skipping...'
    #     return

    subscription_id = vm_metadata["compute"]["subscriptionId"]
    location = vm_metadata["compute"]["location"]
    resource_group = vm_metadata["compute"]["resourceGroupName"]

    random_suffix = ''.join(random.SystemRandom().choice(
        ascii_lowercase) for _ in range(14))

    cyclecloud_admin_pw = ""
    
    if password:
        print 'Password specified, using it as the admin password'
        cyclecloud_admin_pw = password
    else:
        random_pw_chars = ([random.choice(ascii_lowercase) for _ in range(20)] +
                        [random.choice(ascii_uppercase) for _ in range(20)] +
                        [random.choice(digits) for _ in range(10)])
        random.shuffle(random_pw_chars)
        cyclecloud_admin_pw = ''.join(random_pw_chars)

    if storageAccount:
        print 'Storage account specified, using it as the default locker'
        storage_account_name = storageAccount
    else:
        storage_account_name = 'cyclecloud' + random_suffix

    azure_data = {
        "Environment": azure_cloud,
        "AzureRMUseManagedIdentity": use_managed_identity,
        "AzureResourceGroup": resource_group,
        "AzureRMApplicationId": application_id,
        "AzureRMApplicationSecret": application_secret,
        "AzureRMSubscriptionId": subscription_id,
        "AzureRMTenantId": tenant_id,
        "DefaultAccount": True,
        "Location": location,
        "Name": "azure",
        "Provider": "azure",
        "ProviderId": subscription_id,
        "RMStorageAccount": storage_account_name,
        "RMStorageContainer": "cyclecloud"
    }
    if use_managed_identity:
        azure_data["AzureRMUseManagedIdentity"] = True
    

    app_setting_installation = {
        "AdType": "Application.Setting",
        "Name": "cycleserver.installation.complete",
        "Value": True
    }
    initial_user = {
        "AdType": "Application.Setting",
        "Name": "cycleserver.installation.initial_user",
        "Value": admin_user
    }
    account_data = [
        initial_user,
        app_setting_installation
    ]

    if accept_terms:
        # Terms accepted, auto-create login user account as well
        login_user = {
            "AdType": "AuthenticatedUser",
            "Name": admin_user,
            "RawPassword": cyclecloud_admin_pw,
            "Superuser": True
        }
        account_data.append(login_user)

    account_data_file = tmpdir + "/account_data.json"
    azure_data_file = tmpdir + "/azure_data.json"

    with open(account_data_file, 'w') as fp:
        json.dump(account_data, fp)

    with open(azure_data_file, 'w') as fp:
        json.dump(azure_data, fp)

    print "CycleCloud account data:"
    print json.dumps(azure_data)

    copy2(account_data_file, cycle_root + "/config/data/")

    if not accept_terms:
        # reset the installation status so the splash screen re-appears
        print "Resetting installation"
        sql_statement = 'update Application.Setting set Value = false where name ==\"cycleserver.installation.complete\"'
        _catch_sys_error(
            ["/opt/cycle_server/cycle_server", "execute", sql_statement])

    # set the permissions so that the first login works.
    perms_sql_statement = 'update Application.Setting set Value = false where Name == \"authorization.check_datastore_permissions\"'
    _catch_sys_error(
        ["/opt/cycle_server/cycle_server", "execute", perms_sql_statement])

    initialize_cyclecloud_cli(admin_user, cyclecloud_admin_pw)

    output =  _catch_sys_error(["/usr/local/bin/cyclecloud", "account", "show", "azure"])
    if 'Credentials: azure' in output:
        print "Account \"azure\" already exists.   Skipping account setup..."
    else:
        # wait until Managed Identity is ready for use before creating the Account
        if use_managed_identity:
            get_vm_managed_identity()

        # create the cloud provide account
        print "Registering Azure subscription in CycleCloud"
        _catch_sys_error(["/usr/local/bin/cyclecloud", "account",
                        "create", "-f", azure_data_file])


def initialize_cyclecloud_cli(admin_user, cyclecloud_admin_pw):
    print "Setting up azure account in CycleCloud and initializing cyclecloud CLI"

    # wait for the data to be imported
    password_flag = ("--password=%s" % cyclecloud_admin_pw)
    sleep(5)

    print "Initializing cylcecloud CLI"
    _catch_sys_error(["/usr/local/bin/cyclecloud", "initialize", "--loglevel=debug", "--batch",
                      "--url=https://localhost", "--verify-ssl=false", "--username=%s" % admin_user, password_flag])


def letsEncrypt(fqdn, location):
    # FQDN is assumed to be in the form: hostname.location.cloudapp.azure.com
    # fqdn = hostname + "." + location + ".cloudapp.azure.com"
    sleep(60)
    try:
        cmd_list = [cs_cmd, "keystore", "automatic", "--accept-terms", fqdn]
        output = check_output(cmd_list)
        print cmd_list
        print output
    except CalledProcessError as e:
        print "Error getting SSL cert from Lets Encrypt"
        print "Proceeding with self-signed cert"


def get_vm_metadata():
    metadata_url = "http://169.254.169.254/metadata/instance?api-version=2017-08-01"
    metadata_req = Request(metadata_url, headers={"Metadata": True})

    for i in range(30):
        print "Fetching metadata"
        metadata_response = urlopen(metadata_req, timeout=2)

        try:
            return json.load(metadata_response)
        except ValueError as e:
            print "Failed to get metadata %s" % e
            print "    Retrying"
            sleep(2)
            continue
        except:
            print "Unable to obtain metadata after 30 tries"
            raise

def get_vm_managed_identity():
    # Managed Identity may  not be available immediately at VM startup...
    # Test/Pause/Retry to see if it gets assigned
    metadata_url = 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/'
    metadata_req = Request(metadata_url, headers={"Metadata": True})

    for i in range(30):
        print "Fetching managed identity"
        metadata_response = urlopen(metadata_req, timeout=2)

        try:
            return json.load(metadata_response)
        except ValueError as e:
            print "Failed to get managed identity %s" % e
            print "    Retrying"
            sleep(10)
            continue
        except:
            print "Unable to obtain managed identity after 30 tries"
            raise    

def start_cc():
    import glob
    print "(Re-)Starting CycleCloud server"
    _catch_sys_error([cs_cmd, "stop"])
    if glob.glob("/opt/cycle_server/data/ads/corrupt*") or glob.glob("/opt/cycle_server/data/ads/*logfile_failure"):
        print "WARNING: Corrupted datastore masterlog detected.   Restoring from last backup..."
        if not glob.glob("/opt/cycle_server/data/backups/backup-*"):
            raise Exception("ERROR: No backups found, but master.logfile is corrupt!")
        try:
            yes = subprocess.Popen(['echo', 'yes'], stdout=subprocess.PIPE)
            output = subprocess.check_output(['/opt/cycle_server/util/restore.sh'], stdin=yes.stdout)
            yes.wait()
            print output
        except CalledProcessError as e:
            print "Error with cmd: %s" % e.cmd
            print "Output: %s" % e.output
            raise
    
    _catch_sys_error([cs_cmd, "start"])

    # Retry await_startup in case it takes much longer than expected 
    # (this is common in local testing with limited compute resources)
    max_tries = 3
    started = False
    while not started:
        try:
            max_tries -= 1
            _catch_sys_error([cs_cmd, "await_startup"])
            started = True
        except:
            if max_tries >  0:
                print "Retrying..."
            else:
                raise 


def modify_cs_config():
    print "Editing CycleCloud server system properties file"
    # modify the CS config files
    cs_config_file = cycle_root + "/config/cycle_server.properties"

    fh, tmp_cs_config_file = mkstemp()
    with fdopen(fh, 'w') as new_config:
        with open(cs_config_file) as cs_config:
            for line in cs_config:
                if line.startswith('webServerMaxHeapSize='):
                    new_config.write('webServerMaxHeapSize=4096M\n')
                elif line.startswith('webServerPort='):
                    new_config.write('webServerPort=80\n')
                elif line.startswith('webServerSslPort='):
                    new_config.write('webServerSslPort=443\n')
                elif line.startswith('webServerEnableHttps='):
                    new_config.write('webServerEnableHttps=true\n')
                else:
                    new_config.write(line)

    remove(cs_config_file)
    move(tmp_cs_config_file, cs_config_file)

    #Ensure that the files are created by the cycleserver service user
    _catch_sys_error(["chown", "-R", "cycle_server.", cycle_root])

def install_cc_cli():
    # CLI comes with an install script but that installation is user specific
    # rather than system wide.
    # Downloading and installing pip, then using that to install the CLIs
    # from source.
    if os.path.exists("/usr/local/bin/cyclecloud"):
        print "CycleCloud CLI already installed."
        return

    print "Unzip and install CLI"
    chdir(tmpdir)
    _catch_sys_error(["unzip", "/opt/cycle_server/tools/cyclecloud-cli.zip"])
    for cli_install_dir in listdir("."):
        if path.isdir(cli_install_dir) and re.match("cyclecloud-cli-installer", cli_install_dir):
            print "Found CLI install DIR %s" % cli_install_dir
            chdir(cli_install_dir)
            _catch_sys_error(["./install.sh", "--system"])


def already_installed():
    print "Checking for existing Azure CycleCloud install"
    return os.path.exists("/opt/cycle_server/cycle_server")

def download_install_cc():
    print "Installing Azure CycleCloud server"
    _catch_sys_error(["yum", "install", "-y", "cyclecloud"])


def configure_msft_yum_repos():
    print "Configuring Microsoft yum repository for CycleCloud install"
    _catch_sys_error(
        ["rpm", "--import", "https://packages.microsoft.com/keys/microsoft.asc"])

    with open('/etc/yum.repos.d/cyclecloud.repo', 'w') as f:
        f.write("""\
[cyclecloud]
name=cyclecloud
baseurl=https://packages.microsoft.com/yumrepos/cyclecloud
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
""")

    with open('/etc/yum.repos.d/azure-cli.repo', 'w') as f:
        f.write("""\
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc      
""")


def install_pre_req():
    print "Installing pre-requisites for CycleCloud server"
    _catch_sys_error(["yum", "install", "-y", "java-1.8.0-openjdk-headless"])

    # not strictly needed, but it's useful to have the AZ CLI
    # Taken from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-yum?view=azure-cli-latest
    _catch_sys_error(["yum", "install", "-y", "azure-cli"])


def main():

    parser = argparse.ArgumentParser(description="usage: %prog [options]")

    parser.add_argument("--azureSovereignCloud",
                        dest="azureSovereignCloud",
                        default="public",
                        help="Azure Region [china|germany|public|usgov]")

    parser.add_argument("--tenantId",
                        dest="tenantId",
                        help="Tenant ID of the Azure subscription")

    parser.add_argument("--applicationId",
                        dest="applicationId",
                        help="Application ID of the Service Principal")

    parser.add_argument("--applicationSecret",
                        dest="applicationSecret",
                        help="Application Secret of the Service Principal")

    parser.add_argument("--username",
                        dest="username",
                        help="The local admin user for the CycleCloud VM")

    parser.add_argument("--hostname",
                        dest="hostname",
                        help="The short public hostname assigned to this VM (or public IP), used for LetsEncrypt")

    parser.add_argument("--acceptTerms",
                        dest="acceptTerms",
                        action="store_true",
                        help="Accept Cyclecloud terms and do a silent install")

    parser.add_argument("--useLetsEncrypt",
                        dest="useLetsEncrypt",
                        action="store_true",
                        help="Automatically fetch certificate from Let's Encrypt.  (Only suitable for installations with public IP.)")

    parser.add_argument("--useManagedIdentity",
                        dest="useManagedIdentity",
                        action="store_true",
                        help="Use the first assigned Managed Identity rather than a Service Principle for the default account")

    parser.add_argument("--dryrun",
                        dest="dryrun",
                        action="store_true",
                        help="Allow local testing outside Azure Docker")

    parser.add_argument("--password",
                        dest="password",
                        help="The password for the CycleCloud UI user")

    parser.add_argument("--publickey",
                        dest="publickey",
                        help="The public ssh key for the CycleCloud UI user")

    parser.add_argument("--storageAccount",
                        dest="storageAccount",
                        help="The storage account to use as a CycleCloud locker")

    parser.add_argument("--resourceGroup",
                        dest="resourceGroup",
                        help="The resource group for CycleCloud cluster resources.  Resource Group must already exist.  (Default: same RG as CycleCloud)")

    args = parser.parse_args()

    print("Debugging arguments: %s" % args)

    if not already_installed():
        configure_msft_yum_repos()
        install_pre_req()
        download_install_cc()
        modify_cs_config()

    start_cc()

    install_cc_cli()

    if not args.dryrun:
        vm_metadata = get_vm_metadata()
    else:
        vm_metadata = {"compute": {
            "subscriptionId": "1234-50-679890",
            "location": "dryrun",
            "resourceGroupName": "dryrun-rg"}}

    if args.resourceGroup:
        print("CycleCloud created in resource group: %s" % vm_metadata["compute"]["resourceGroupName"])
        print("Cluster resources will be created in resource group: %s" %  args.resourceGroup)
        vm_metadata["compute"]["resourceGroupName"] = args.resourceGroup

    cyclecloud_account_setup(vm_metadata, args.useManagedIdentity, args.tenantId, args.applicationId,
                             args.applicationSecret, args.username, args.azureSovereignCloud,
                             args.acceptTerms, args.password, args.storageAccount)

    if args.useLetsEncrypt:
        letsEncrypt(args.hostname, vm_metadata["compute"]["location"])

    #  TODO: Replace with list of initial usernames/pub. keys
    create_user_credential(args.username, args.publickey)

    clean_up()


if __name__ == "__main__":
    try:
        main()
    except:
        print("Deployment failed...   Staying alive for DEBUGGING")

