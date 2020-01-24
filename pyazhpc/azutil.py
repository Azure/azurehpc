import logging
import shlex
import subprocess

def _make_subprocess_error_string(res):
    return "\n    args={}\n    return code={}\n    stdout={}\n    stderr={}".format(res.args, res.returncode, res.stdout, res.stderr)

def get_subscription():
    cmd = "az account show --output tsv --query '[name,id]'"
    proc = subprocess.run(shlex.split(cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    print(proc.stdout)
    print(proc.stderr)
    print(proc.returncode)

def get_keyvault_secret(vault, key):
    cmd = """
        az keyvault secret show \
            --name {} --vault-name {} \
            --query value --output tsv \
    """.format(key, vault)
    res = subprocess.run(shlex.split(cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
    out = res.stdout.splitlines()
    if len(out) != 1:
        logging.error("expected output"+_make_subprocess_error_string(res))
    secret = out[0].decode('utf-8')
    return secret

def get_storage_url(account)
    cmd = """
        az storage account show \
            --name {} \
            --query primaryEndpoints.blob \
            --output tsv \
    """.format(account)
    res = subprocess.run(shlex.split(cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
    out = res.stdout.splitlines()
    if len(out) != 1:
        logging.error("unexpected output"+_make_subprocess_error_string(res))
    url = out[0].decode('utf-8')
    return url

def get_storage_key(account)
    cmd = """
        az storage account keys list 
            --account-name {} --query "[0].value" --output tsv
    """.format(account)
    res = subprocess.run(shlex.split(cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
    out = res.stdout.splitlines()
    if len(out) != 1:
        logging.error("unexpected output"+_make_subprocess_error_string(res))
    key = out[0].decode('utf-8')
    return key

def get_storage_saskey(account, container):
    cmd = """
        az storage container generate-sas \
            --account-name {} \
            --name {} \
            --permissions r \
            --start {} \
            --expiry {} \
            --output tsv \
    """.format(
        account, container
        (datetime.datetime.utcnow() - datetime.timedelta(hours=2)).strftime("%Y-%m-%dT%H:%M:%SZ"),
        (datetime.datetime.utcnow() + datetime.timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
    )
    res = subprocess.run(shlex.split(cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        logging.error("invalid returncode"+_make_subprocess_error_string(res))
    out = res.stdout.splitlines()
    if len(out) != 1:
        logging.error("unexpected output"+_make_subprocess_error_string(res))
    saskey = out[0].decode('utf-8')
    return saskey

