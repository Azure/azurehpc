import argparse
import json
import logging
import os
import shutil
import time

import arm
import azconfig
import azinstall
import azutil

from cryptography.hazmat.primitives import serialization as crypto_serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend as crypto_default_backend

log = logging.getLogger(__name__)

def do_preprocess(args):
    log.debug("reading config file ({})".format(args.config_file))
    config = azconfig.ConfigFile()
    config.open(args.config_file)
    print(json.dumps(config.preprocess(), indent=4))

def do_get(args):
    config = azconfig.ConfigFile()
    config.open(args.config_file)
    val = config.read_value(args.path)
    print(f"{args.path} = {val}")


def do_scp(args):
    log.debug("reading config file ({})".format(args.config_file))
    c = azconfig.ConfigFile()
    c.open(args.config_file)
    
    adminuser = c.read_value("admin_user")
    sshkey="{}_id_rsa".format(adminuser)
    # TODO: check ssh key exists

    jumpbox = c.read_value("install_from")
    rg = c.read_value("resource_group")
    fqdn = azutil.get_fqdn(rg, jumpbox+"pip")

    scp_exe = "scp"
    scp_cmd = [
            scp_exe,
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-i", sshkey,
            "-o", f"ProxyCommand=ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i {sshkey} -W %h:%p {adminuser}@{fqdn}"
        ] + args.args
    log.debug(" ".join([ f"'{a}'" for a in scp_cmd ]))
    os.execvp(scp_exe, scp_cmd)

def do_connect(args):
    log.debug("reading config file ({})".format(args.config_file))
    c = azconfig.ConfigFile()
    c.open(args.config_file)
    
    adminuser = c.read_value("admin_user")
    ssh_private_key="{}_id_rsa".format(adminuser)
    # TODO: check ssh key exists
    
    if args.user == None:
        sshuser = adminuser
    else:
        sshuser = args.user

    jumpbox = c.read_value("install_from")
    resource_group = c.read_value("resource_group")
    fqdn = azutil.get_fqdn(resource_group, jumpbox+"pip")

    if fqdn == "":
        log.warning("The install node does not have a public IP - trying hostname ({})".format(jumpbox))

    target = args.resource
    
    rtype = c.read_value(f"resources.{args.resource}.type")

    if rtype == "vm":
        instances = c.read_value(f"resources.{args.resource}.instances", 1)
        print(instances)

        if instances > 1:
            target = "{}{:04}".format(args.resource, 1)
            log.info("Multiple instances of {}, connecting to {}")
    
    elif rtype == "vmss":
        vmssnodes = azutil.get_vmss_instances(resource_group, args.resource)
        if len(vmssnodes) == 0:
            log.error("There are no instances in the vmss")
            sys.exit(1)
        target = vmssnodes[0]

    ssh_exe = "ssh"
    cmdline = []
    if len(args.args) > 0:
        cmdline.append(" ".join(args.args))

    if args.resource == jumpbox:
        log.info("logging directly into {}".format(fqdn))
        ssh_args = [
            "ssh", "-t", "-q", 
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-i", ssh_private_key,
            f"{sshuser}@{fqdn}"
        ]
        log.debug(" ".join(ssh_args + cmdline))
        os.execvp(ssh_exe, ssh_args + cmdline)
    else:
        log.info("loggging in to {} (via {})".format(target, fqdn))
        ssh_args = [
            ssh_exe, "-t", "-q",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-i", ssh_private_key,
            "-o", f"ProxyCommand=ssh -i {ssh_private_key} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p {sshuser}@{fqdn}",
            f"{sshuser}@{target}"
        ]
        log.debug(" ".join(ssh_args + cmdline))
        os.execvp(ssh_exe, ssh_args + cmdline)

def do_build(args):
    log.debug(f"reading config file ({args.config_file})")
    tmpdir = "azhpc_install_" + os.path.basename(args.config_file).strip(".json")
    log.debug(f"tmpdir = {tmpdir}")
    if os.path.isdir(tmpdir):
        log.debug("removing existing tmp directory")
        shutil.rmtree(tmpdir)

    c = azconfig.ConfigFile()
    c.open(args.config_file)
    config = c.preprocess()

    adminuser = config["admin_user"]
    private_key_file = adminuser+"_id_rsa"
    public_key_file = adminuser+"_id_rsa.pub"
    if not (os.path.exists(private_key_file) and os.path.exists(public_key_file)):
        # create ssh keys
        key = rsa.generate_private_key(
            backend=crypto_default_backend(),
            public_exponent=65537,
            key_size=2048
        )
        private_key = key.private_bytes(
            crypto_serialization.Encoding.PEM,
            crypto_serialization.PrivateFormat.TraditionalOpenSSL,
            crypto_serialization.NoEncryption())
        public_key = key.public_key().public_bytes(
            crypto_serialization.Encoding.OpenSSH,
            crypto_serialization.PublicFormat.OpenSSH
        )
        with open(private_key_file, "wb") as f:
            os.chmod(private_key_file, 0o600)
            f.write(private_key)
        with open(public_key_file, "wb") as f:
            os.chmod(public_key_file, 0o644)
            f.write(public_key+b'\n')

    tpl = arm.ArmTemplate()
    tpl.read(config)

    log.info("writing out arm template to " + args.output_template)
    with open(args.output_template, "w") as f:
        f.write(tpl.to_json())

    log.info("creating resource group " + config["resource_group"])
    azutil.create_resource_group(
        config["resource_group"],
        config["location"]
    )
    log.info("deploying arm template")
    azutil.deploy(
        config["resource_group"],
        args.output_template
    )
    log.info("building host lists")
    azinstall.generate_hostlists(config, tmpdir)
    log.info("building install scripts")
    azinstall.generate_install(config, tmpdir, adminuser, private_key_file, public_key_file)
    
    jumpbox = config.get("install_from", None)
    fqdn = None
    if jumpbox:
        fqdn = azutil.get_fqdn(config["resource_group"], jumpbox+"pip")
    log.info("running install scripts")
    azinstall.run(config, tmpdir, adminuser, private_key_file, public_key_file, fqdn)

def do_destroy(args):
    log.info("reading config file ({})".format(args.config_file))
    config = azconfig.ConfigFile()  
    config.open(args.config_file)

    log.warning("deleting entire resource group ({})".format(config.read_value("resource_group")))
    if not args.force:
        log.info("you have 10s to change your mind and ctrl-c!")
        time.sleep(10)
        log.info("too late!")

    azutil.delete_resource_group(
        config.read_value("resource_group"), args.no_wait
    )

if __name__ == "__main__":
    azhpc_parser = argparse.ArgumentParser(prog="azhpc")
    
    gopt_parser = argparse.ArgumentParser()
    gopt_parser.add_argument(
        "--config-file", "-c", type=str, 
        default="config.json", help="config file"
    )
    gopt_parser.add_argument(
        "-v", "--verbose", 
        help="increase output verbosity",
        action="store_true"
    )

    subparsers = azhpc_parser.add_subparsers(help="actions")

    preprocess_parser = subparsers.add_parser(
        "preprocess", 
        parents=[gopt_parser],
        add_help=False,
        description="preprocess the config file",
        help="expand all the config macros"
    )
    preprocess_parser.set_defaults(func=do_preprocess)

    get_parser = subparsers.add_parser(
        "get",
        parents=[gopt_parser],
        add_help=False,
        description="get a config value",
        help="evaluate the value at the json path specified"
    )
    get_parser.set_defaults(func=do_get)
    get_parser.add_argument(
        "path", 
        type=str,
        help="the json path to evaluate"
    )

    build_parser = subparsers.add_parser(
        "build", 
        parents=[gopt_parser],
        add_help=False,
        description="deploy the config",
        help="create an arm template and deploy"
    )
    build_parser.set_defaults(func=do_build)
    build_parser.add_argument(
        "--output-template", 
        "-o", 
        type=str, 
        default="deploy.json", 
        help="filename for the arm template",
    )

    destroy_parser = subparsers.add_parser(
        "destroy", 
        parents=[gopt_parser],
        add_help=False,
        description="delete the resource group",
        help="delete entire resource group"
    )
    destroy_parser.set_defaults(func=do_destroy)
    destroy_parser.add_argument(
        "--force", 
        action="store_true",
        default=False,
        help="delete resource group immediately"
    )
    destroy_parser.add_argument(
        "--no-wait", 
        action="store_true",
        default=False,
        help="do not wait for resources to be deleted"
    )
    
    connect_parser = subparsers.add_parser(
        "connect", 
        parents=[gopt_parser],
        add_help=False,
        description="connect to a resource",
        help="connect to a resource with 'ssh'"
    )
    connect_parser.set_defaults(func=do_connect)
    connect_parser.add_argument(
        "--user", 
        "-u", 
        type=str,
        help="the user to connect as",
    )
    connect_parser.add_argument(
        "resource", 
        type=str,
        help="the resource to connect to"
    )
    connect_parser.add_argument(
        'args', 
        nargs=argparse.REMAINDER,
        help="additional arguments will be passed to the ssh command"
    )

    scp_parser = subparsers.add_parser(
        "scp", 
        parents=[gopt_parser],
        add_help=False,
        description="secure copy",
        help="copy files to a resource with 'scp'"
    )
    scp_parser.set_defaults(func=do_scp)
    scp_parser.add_argument(
        'args', 
        nargs=argparse.REMAINDER,
        help="the arguments passed to scp"
    )

    args = azhpc_parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG, format='%(asctime)s:%(filename)s:%(lineno)d:%(levelname)s:%(message)s')
    else:
        logging.basicConfig(level=logging.INFO, format='%(asctime)s:%(levelname)s:%(message)s')

    log.debug(args)

    args.func(args)

