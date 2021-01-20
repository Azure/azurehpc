#!/usr/bin/python
# Prepare an Azure provider account for CycleCloud usage.
import os
import argparse
import json
import re
import random
import platform
from string import ascii_uppercase, ascii_lowercase, digits
from subprocess import CalledProcessError, check_output
from os import path, listdir, chdir, fdopen, remove
from urllib2 import urlopen, Request, HTTPError, URLError
from urllib import urlretrieve
from shutil import rmtree, copy2, move
from tempfile import mkstemp, mkdtemp
from time import sleep


tmpdir = mkdtemp()
print("Creating temp directory %s for installing CycleCloud" % tmpdir)
cycle_root = "/opt/cycle_server"
cs_cmd = cycle_root + "/cycle_server"


def clean_up():
    rmtree(tmpdir)

def _catch_sys_error(cmd_list):
    try:
        output = check_output(cmd_list)
        print(cmd_list)
        print(output)
        return output
    except CalledProcessError as e:
        print("Error with cmd: %s" % e.cmd)
        print("Output: %s" % e.output)
        raise

def create_user(username):
    import pwd
    try:
        pwd.getpwnam(username)
    except KeyError:
        print('Creating user %s' % username)
        _catch_sys_error(["useradd", "-m", "-d", "/home/"+username, username])
    _catch_sys_error(["chown", "-R", username + ":" + username, "/home/"+username])

def create_keypair(username, public_key=None):
    if not os.path.isdir("/home/"+username+"/.ssh"):
        _catch_sys_error(["mkdir", "-p", "/home/"+username+"/.ssh"])
    public_key_file  = "/home/"+username+"/.ssh/id_rsa.pub"
    if not os.path.exists(public_key_file):
        if public_key:
            with open(public_key_file, 'w') as pubkeyfile:
                pubkeyfile.write(public_key)
                pubkeyfile.write("\n")
        else:
            _catch_sys_error(["ssh-keygen", "-f", "/home/"+username+"/.ssh/id_rsa", "-N", ""])
            with open(public_key_file, 'r') as pubkeyfile:
                public_key = pubkeyfile.read()

    authorized_key_file = "/home/"+username+"/.ssh/authorized_keys"
    authorized_keys = ""
    if os.path.exists(authorized_key_file):
        with open(authorized_key_file, 'r') as authkeyfile:
            authorized_keys = authkeyfile.read()
    if public_key not in authorized_keys:
        with open(authorized_key_file, 'w') as authkeyfile:
            authkeyfile.write(public_key)
            authkeyfile.write("\n")
    _catch_sys_error(["chown", "-R", username + ":" + username, "/home/"+username])
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
    credential_data_file = os.path.join(tmpdir, "credential.json")
    print("Creating cred file: %s" % credential_data_file)
    with open(credential_data_file, 'w') as fp:
        json.dump(credential_record, fp)

    config_path = os.path.join(cycle_root, "config/data/")
    print("Copying config to %s" % config_path)
    copy2(credential_data_file, config_path)


def generate_password_string():
    random_pw_chars = ([random.choice(ascii_lowercase) for _ in range(20)] +
                        [random.choice(ascii_uppercase) for _ in range(20)] +
                        [random.choice(digits) for _ in range(10)])
    random.shuffle(random_pw_chars)
    return ''.join(random_pw_chars)


def cyclecloud_account_setup(vm_metadata, use_managed_identity, tenant_id, application_id, application_secret,
                             admin_user, azure_cloud, accept_terms, password, storageAccount):

    print("Setting up azure account in CycleCloud and initializing cyclecloud CLI")

    if not accept_terms:
        print("Accept terms was FALSE !!!!!  Over-riding for now...")
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
        print('Password specified, using it as the admin password')
        cyclecloud_admin_pw = password
    else:
        cyclecloud_admin_pw = generate_password_string()

    if storageAccount:
        print('Storage account specified, using it as the default locker')
        storage_account_name = storageAccount
    else:
        storage_account_name = 'cyclecloud'+random_suffix

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

    print("CycleCloud account data:")
    print(json.dumps(azure_data))

    copy2(account_data_file, cycle_root + "/config/data/")

    if not accept_terms:
        # reset the installation status so the splash screen re-appears
        print("Resetting installation")
        sql_statement = 'update Application.Setting set Value = false where name ==\"cycleserver.installation.complete\"'
        _catch_sys_error(
            ["/opt/cycle_server/cycle_server", "execute", sql_statement])

    # set the permissions so that the first login works.
    perms_sql_statement = 'update Application.Setting set Value = false where Name == \"authorization.check_datastore_permissions\"'
    _catch_sys_error(
        ["/opt/cycle_server/cycle_server", "execute", perms_sql_statement])

    initialize_cyclecloud_cli(admin_user, cyclecloud_admin_pw)

    output =  _catch_sys_error(["/usr/local/bin/cyclecloud", "account", "show", "azure"])
    if 'Credentials: azure' in str(output):
        print("Account \"azure\" already exists.   Skipping account setup...")
    else:
        # wait until Managed Identity is ready for use before creating the Account
        if use_managed_identity:
            get_vm_managed_identity()

        # create the cloud provide account
        print("Registering Azure subscription in CycleCloud")
        _catch_sys_error(["/usr/local/bin/cyclecloud", "account",
                        "create", "-f", azure_data_file])


def initialize_cyclecloud_cli(admin_user, cyclecloud_admin_pw):
    print("Setting up azure account in CycleCloud and initializing cyclecloud CLI")

    # wait for the data to be imported
    password_flag = ("--password=%s" % cyclecloud_admin_pw)
    sleep(5)

    print("Initializing cylcecloud CLI")
    _catch_sys_error(["/usr/local/bin/cyclecloud", "initialize", "--loglevel=debug", "--batch",
                      "--url=https://localhost", "--verify-ssl=false", "--username=%s" % admin_user, password_flag])


def letsEncrypt(fqdn, location):
    # FQDN is assumed to be in the form: hostname.location.cloudapp.azure.com
    # fqdn = hostname + "." + location + ".cloudapp.azure.com"
    sleep(60)
    try:
        cmd_list = [cs_cmd, "keystore", "automatic", "--accept-terms", fqdn]
        output = check_output(cmd_list)
        print(cmd_list)
        print(output)
    except CalledProcessError as e:
        print("Error getting SSL cert from Lets Encrypt")
        print("Proceeding with self-signed cert")


def get_vm_metadata():
    metadata_url = "http://169.254.169.254/metadata/instance?api-version=2017-08-01"
    metadata_req = Request(metadata_url, headers={"Metadata": True})

    for _ in range(30):
        print("Fetching metadata")
        metadata_response = urlopen(metadata_req, timeout=2)

        try:
            return json.load(metadata_response)
        except ValueError as e:
            print("Failed to get metadata %s" % e)
            print("    Retrying")
            sleep(2)
            continue
        except:
            print("Unable to obtain metadata after 30 tries")
            raise

def get_vm_managed_identity():
    # Managed Identity may  not be available immediately at VM startup...
    # Test/Pause/Retry to see if it gets assigned
    metadata_url = 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/'
    metadata_req = Request(metadata_url, headers={"Metadata": True})

    for _ in range(30):
        print("Fetching managed identity")
        metadata_response = urlopen(metadata_req, timeout=2)

        try:
            return json.load(metadata_response)
        except ValueError as e:
            print("Failed to get managed identity %s" % e)
            print("    Retrying")
            sleep(10)
            continue
        except:
            print("Unable to obtain managed identity after 30 tries")
            raise    

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

    vm_metadata = get_vm_metadata()

    if args.resourceGroup:
        print("CycleCloud created in resource group: %s" % vm_metadata["compute"]["resourceGroupName"])
        print("Cluster resources will be created in resource group: %s" %  args.resourceGroup)
        vm_metadata["compute"]["resourceGroupName"] = args.resourceGroup

    cyclecloud_account_setup(vm_metadata, args.useManagedIdentity, args.tenantId, args.applicationId,
                             args.applicationSecret, args.username, args.azureSovereignCloud,
                             args.acceptTerms, args.password, args.storageAccount)

    if args.useLetsEncrypt:
        letsEncrypt(args.hostname, vm_metadata["compute"]["location"])

    #  Create user requires root privileges
    create_user_credential(args.username, args.publickey)

    clean_up()


if __name__ == "__main__":
    try:
        main()
    except:
        print("Deployment failed...   Staying alive for DEBUGGING")

