import datetime
import logging
import shlex
import subprocess
import sys

log = logging.getLogger(__name__)

def _make_subprocess_error_string(res):
    return "\n    args={}\n    return code={}\n    stdout={}\n    stderr={}".format(res.args, res.returncode, res.stdout.decode("utf-8"), res.stderr.decode("utf-8"))

def get_subscription():
    cmd = [ "az", "account", "show", "--output", "tsv", "--query", "[name,id]" ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)
    return res.stdout

def get_vm_private_ip(resource_group, vm_name):
    cmd = [
        "az", "vm", "list-ip-addresses",
            "--resource-group", resource_group,
            "--name", vm_name,
            "--query", "[0].virtualMachine.network.privateIpAddresses",
            "--output", "tsv"
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)
    out = res.stdout.splitlines()
    return out[0].decode("utf-8")

def get_fqdn(resource_group, public_ip):
    cmd = [ 
        "az", "network", "public-ip", "show", 
            "--resource-group", resource_group,
            "--name", public_ip,
            "--query", "dnsSettings.fqdn",
            "--output", "tsv"
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)
    out = res.stdout.splitlines()
    return out[0].decode("utf-8")

def get_vmss_instances(resource_group, vmss_name):
    cmd = [ 
        "az", "vmss", "list-instances",
            "--resource-group", resource_group,
            "--name", vmss_name,
            "--query", "[].osProfile.computerName",
            "--output", "tsv"
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)
    names = [ x.decode("utf-8") for x in res.stdout.splitlines() ]
    return names

def create_resource_group(resource_group, location):
    log.debug("creating resource group")
    cmd = [
        "az", "group", "create",
            "--name", resource_group,
            "--location", location
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)

def delete_resource_group(resource_group, nowait):
    log.debug("deleting resource group")
    cmd = [
        "az", "group", "delete",
            "--name", resource_group, "--yes"
    ]
    if nowait == True:
        cmd.append("--no-wait")
    log.debug(" ".join(cmd))
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)


def deploy(resource_group, arm_template):
    log.debug("deploying template")
    cmd = [
        "az", "group", "deployment", "create",
            "--resource-group", resource_group,
            "--template-file", arm_template
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)

def get_keyvault_secret(vault, key):
    cmd = [
        "az", "keyvault", "secret", "show",
            "--name", key, "--vault-name", vault,
            "--query", "value", "--output", "tsv"
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
    out = res.stdout.splitlines()
    if len(out) != 1:
        logging.error("expected output"+_make_subprocess_error_string(res))
    secret = out[0].decode('utf-8')
    return secret

def get_storage_url(account):
    cmd = [
        "az", "storage", "account", "show",
            "--name", account,
            "--query", "primaryEndpoints.blob",
            "--output", "tsv"
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
    out = res.stdout.splitlines()
    if len(out) != 1:
        logging.error("unexpected output"+_make_subprocess_error_string(res))
    url = out[0].decode('utf-8')
    return url

def get_storage_key(account):
    cmd = [
        "az", "storage", "account", "keys", "list",
            "--account-name", account,
            "--query", "[0].value", 
            "--output", "tsv"
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
    out = res.stdout.splitlines()
    if len(out) != 1:
        logging.error("unexpected output"+_make_subprocess_error_string(res))
    key = out[0].decode('utf-8')
    return key

def get_storage_saskey(account, container):
    start = (datetime.datetime.utcnow() - datetime.timedelta(hours=2)).strftime("%Y-%m-%dT%H:%M:%SZ")
    expiry = (datetime.datetime.utcnow() + datetime.timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    cmd = [
        "az", "storage", "container", "generate-sas",
            "--account-name", account,
            "--name", container,
            "--permissions", "r",
            "--start", start,
            "--expiry", expiry,
            "--output", "tsv"
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
    out = res.stdout.splitlines()
    if len(out) != 1:
        logging.error("unexpected output"+_make_subprocess_error_string(res))
    saskey = out[0].decode('utf-8')
    return saskey

def get_log_analytics_workspace(resource_group, name):
    cmd = [
        "az", "monitor", "log-analytics", "workspace", "list",
            "--query", f"[?name=='{name}'&&resourceGroup=='{resource_group}'].customerId",
            "--output", "tsv"
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
    out = res.stdout.splitlines()
    if len(out) != 1:
        logging.error("unexpected output"+_make_subprocess_error_string(res))
    saskey = out[0].decode('utf-8')
    return saskey

def get_log_analytics_key(resource_group, name):
    cmd = [
        "az", "monitor", "log-analytics", "workspace", "get-shared-keys",
            "--workspace-name", name,
            "--resource-group", resource_group,
            "--query", "primarySharedKey",
            "--output", "tsv"
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
    out = res.stdout.splitlines()
    if len(out) != 1:
        logging.error("unexpected output"+_make_subprocess_error_string(res))
    saskey = out[0].decode('utf-8')
    return saskey

def get_acr_key(name):
    cmd = [
        "az", "acr", "credential", "show",
            "--name", name,
            "--query", "passwords[0].value",
            "--output", "tsv"
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
    out = res.stdout.splitlines()
    if len(out) != 1:
        logging.error("unexpected output"+_make_subprocess_error_string(res))
    saskey = out[0].decode('utf-8')
    return saskey


