import argparse
import datetime
import json
import os
import re
import shutil
import sys
import textwrap
import time

import arm
import azconfig
import azinstall
import azlog
import azutil

from cryptography.hazmat.primitives import serialization as crypto_serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend as crypto_default_backend

log = azlog.getLogger(__name__)

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

def __add_unset_vars(vset, config_file):
    log.debug(f"looking for vars in {config_file}")
    config = azconfig.ConfigFile()
    config.open(config_file)
    vset.update(config.get_unset_vars())

def do_init(args):
    if not os.path.exists(args.config_file):
        log.error("config file/dir does not exist")
        sys.exit(1)

    if args.show:
        vlist = set()

        if os.path.isfile(args.config_file):
            __add_unset_vars(vlist, args.config_file)
        else:
            for root, dirs, files in os.walk(args.config_file):
                for name in files:
                    if os.path.splitext(name)[1] == ".json":
                        __add_unset_vars(vlist, os.path.join(root, name))

        print("Variables to set: " + ",".join(vlist))
        print()
        print("Example string for '--vars' argument (add values):")
        print("    --vars " + ",".join([ x+"=" for x in vlist ]))
    else:
        log.debug("creating directory")
        os.makedirs(args.dir, exist_ok=True)

        if os.path.isfile(args.config_file):
            shutil.copy(args.config_file, args.dir)
        elif os.path.isdir(args.config_file):
            for root, dirs, files in os.walk(args.config_file):
                for d in dirs:
                    newdir = os.path.join(
                        args.dir,
                        os.path.relpath(
                            os.path.join(root, d),
                            args.config_file
                        )
                    )
                    log.debug("creating directory: " + newdir)
                    os.makedirs(newdir, exist_ok=True)
                for f in files:
                    oldfile = os.path.join(root, f)
                    newfile = os.path.join(
                        args.dir,
                        os.path.relpath(
                            os.path.join(root, f),
                            args.config_file
                        )
                    )
                    log.debug(f"copying file: {oldfile} -> {newfile}")
                    shutil.copy(oldfile, newfile, follow_symlinks=False)

        # get vars
        vset = {}
        if args.vars:
            for vp in args.vars.split(","):
                vk, vv = vp.split("=", 1)
                vset[vk] = vv
            
            for root, dirs, files in os.walk(args.dir):
                for name in files:
                    if os.path.splitext(name)[1] == ".json":
                        config = azconfig.ConfigFile()
                        config.open(os.path.join(root, name))
                        config.replace_vars(vset)
                        config.save(os.path.join(root, name))

def do_scp(args):
    log.debug("reading config file ({})".format(args.config_file))
    c = azconfig.ConfigFile()
    c.open(args.config_file)
    
    adminuser = c.read_value("admin_user")
    sshkey="{}_id_rsa".format(adminuser)
    # TODO: check ssh key exists

    fqdn = c.get_install_from_destination()
    if not fqdn:
        log.error(f"Missing 'install_from' property")
        sys.exit(1)

    if args.args and args.args[0] == "--":
        scp_args = args.args[1:]
    else:
        scp_args = args.args

    scp_exe = "scp"
    scp_cmd = [
            scp_exe, "-q",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-i", sshkey,
            "-o", f"ProxyCommand=ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i {sshkey} -W %h:%p {adminuser}@{fqdn}"
        ] + scp_args
    log.debug(" ".join([ f"'{a}'" for a in scp_cmd ]))
    os.execvp(scp_exe, scp_cmd)

def do_connect(args):
    log.debug("reading config file ({})".format(args.config_file))
    c = azconfig.ConfigFile()
    c.open(args.config_file)
    
    adminuser = c.read_value("admin_user")
    ssh_private_key="{}_id_rsa".format(adminuser)
    # TODO: check ssh key exists
    
    if not args.user:
        sshuser = adminuser
    else:
        sshuser = args.user

    jumpbox = c.read_value("install_from")
    if not jumpbox:
        log.error(f"Missing 'install_from' property")
        sys.exit(1)

    resource_group = c.read_value("resource_group")
    fqdn = c.get_install_from_destination()
 
    log.debug("Getting resource name")

    rtype = c.read_value(f"resources.{args.resource}.type", "hostname")
    rimage = c.read_value(f"resources.{args.resource}.image", "hostname")
    log.debug(f"image is - {rimage}")

    target = args.resource

    if rtype == "vm":
        instances = c.read_value(f"resources.{args.resource}.instances", 1)
        
        if instances > 1:
            target = f"{args.resource}{1:04}"
            log.info(f"Multiple instances of {args.resource}, connecting to {target}")
    
    elif rtype == "vmss":
        vmssnodes = azutil.get_vmss_instances(resource_group, args.resource)
        if len(vmssnodes) == 0:
            log.error("There are no instances in the vmss")
            sys.exit(1)
        target = vmssnodes[0]
        if len(vmssnodes) > 1:
            log.info(f"Multiple instances of {args.resource}, connecting to {target}")

    elif rtype == "hostname":
        pass

    else:
        log.debug(f"Unknown resource type - {rtype}")
        sys.exit(1)

    ros = rimage.split(':')
    if ros[0] == "MicrosoftWindowsServer":
        log.debug(f"os is - {ros[0]} for node {args.resource}")
        fqdn = azutil.get_fqdn(c.read_value("resource_group"), args.resource+"_pip")
        winpassword = c.read_value("variables.win_password")
        log.debug(f"fqdn is {fqdn} for node {args.resource}")
        cmdkey_exe = "cmdkey.exe"
        mstsc_exe = "mstsc.exe"
        cmdline = []
        if len(args.args) > 0:
            cmdline.append(" ".join(args.args))

        cmdkey_args = [
            "cmdkey.exe", f"/generic:{fqdn}", f"/user:{sshuser}", f"/password:{winpassword}"
            ]
        mstsc_args = [
            "mstsc.exe", f"/v:{fqdn}"
            ]
        log.debug(" ".join(cmdkey_args + cmdline))
        cmdkey_cmdline = " ".join(cmdkey_args)
        os.system(cmdkey_cmdline)
        log.debug(" ".join(mstsc_args + cmdline))
        os.execvp(mstsc_exe, mstsc_args)

    else: 
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
            log.info("logging in to {} (via {})".format(target, fqdn))
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

def _exec_command(fqdn, sshuser, sshkey, cmdline):
    ssh_exe = "ssh"
    ssh_args = [
        ssh_exe, "-q", 
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-i", sshkey,
        f"{sshuser}@{fqdn}"
    ]
    log.debug(" ".join(ssh_args + [ cmdline ]))
    os.execvp(ssh_exe, ssh_args + [ cmdline ])

def do_status(args):
    log.debug("reading config file ({})".format(args.config_file))
    c = azconfig.ConfigFile()
    c.open(args.config_file)
    
    adminuser = c.read_value("admin_user")
    ssh_private_key="{}_id_rsa".format(adminuser)

    fqdn = c.get_install_from_destination()
    if not fqdn:
        log.error(f"Missing 'install_from' property")
        sys.exit(1)

    tmpdir = "azhpc_install_" + os.path.basename(args.config_file).strip(".json")
    _exec_command(fqdn, adminuser, ssh_private_key, f"pssh -h {tmpdir}/hostlists/linux -i -t 0 'printf \"%-20s%s\n\" \"$(hostname)\" \"$(uptime)\"' | grep -v SUCCESS")


def do_run(args):
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
    if not jumpbox:
        log.error(f"Missing 'install_from' property")
        sys.exit(1)

    # TODO : Why is this unused ?
    resource_group = c.read_value("resource_group")
    fqdn = c.get_install_from_destination()

    hosts = []
    if args.nodes:
        for r in args.nodes.split(" "):
            rtype = c.read_value(f"resources.{r}.type")
            if not rtype:
                log.error(f"resource {r} does not exist in config")
                sys.exit(1)
            if rtype == "vm":
                instances = c.read_value(f"resources.{r}.instances", 1)
                if instances == 1:
                    hosts.append(r)
                else:
                    hosts += [ f"{r}{n:04}" for n in range(1, instances+1) ]            
            elif rtype == "vmss":
                hosts += azutil.get_vmss_instances(c.read_value("resource_group"), r)
        
    if not hosts:
        hosts.append(jumpbox)

    hostlist = " ".join(hosts)
    cmd = " ".join(args.args)
    _exec_command(fqdn, sshuser, ssh_private_key, f"pssh -H '{hostlist}' -i -t 0 '{cmd}'")

def _create_private_key(private_key_file, public_key_file):
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

def _wait_for_deployment(resource_group, deploy_name):
    building = True
    success = True
    del_lines = 1
    while building:
        time.sleep(5)
        res = azutil.get_deployment_status(resource_group, deploy_name)
        log.debug(res)
        
        print("\033[F"*del_lines)
        del_lines = 1

        for i in res:
            props = i["properties"]
            status_code = props["statusCode"]
            if props.get("targetResource", None):
                resource_name = props["targetResource"]["resourceName"]
                resource_type = props["targetResource"]["resourceType"]
                del_lines += 1
                print(f"{resource_name:15} {resource_type:47} {status_code:15}")
            else:
                provisioning_state = props["provisioningState"]
                del_lines += 1
                building = False
                if provisioning_state != "Succeeded":
                    success = False

    if success:
        log.info("Provising succeeded")
    else:
        log.error("Provisioning failed")
        for i in res:
            props = i["properties"]
            status_code = props["statusCode"]
            if props.get("targetResource", None):
                resource_name = props["targetResource"]["resourceName"]
                if props.get("statusMessage", None):
                    if "error" in props["statusMessage"]:
                        error_code = props["statusMessage"]["error"]["code"]
                        error_message = textwrap.TextWrapper(width=60).wrap(text=props["statusMessage"]["error"]["message"])
                        error_target = props["statusMessage"]["error"].get("target", None)
                        error_target_str = ""
                        if error_target:
                            error_target_str = f"({error_target})"
                        print(f"  Resource : {resource_name} - {error_code} {error_target_str}")
                        print(f"  Message  : {error_message[0]}")
                        for line in error_message[1:]:
                            print(f"             {line}")
                        if "details" in props["statusMessage"]["error"]:
                            def pretty_print(d, indent=0): 
                                def wrapped_print(indent, text, max_width=80):
                                    lines = textwrap.TextWrapper(width=max_width-indent).wrap(text=text)
                                    for line in lines:
                                        print(" "*indent + line)
                                if isinstance(d, list):
                                    for value in d:
                                        pretty_print(value, indent)
                                elif isinstance(d, dict):
                                    for key, value in d.items(): 
                                        if isinstance(value, dict): 
                                            wrapped_print(indent, str(key)) 
                                            pretty_print(value, indent+4)
                                        elif isinstance(value, list):
                                            wrapped_print(indent, str(key))
                                            pretty_print(value, indent+4)
                                        else: 
                                            wrapped_print(indent, f"{key}: {value}")
                                else:
                                    wrapped_print(indent, str(d))
                            pretty_print(props["statusMessage"]["error"]["details"], 13)

        sys.exit(1)

def do_slurm_suspend(args):
    log.debug(f"reading config file ({args.config_file})")
    
    c = azconfig.ConfigFile()
    c.open(args.config_file)
    config = c.preprocess()

    log.info(f"slurm suspend for {args.nodes}")
    # first get the resource name
    all_resources = config.get("resources", [])
    resource_name, brackets = re.search(r'([^[]*)\[?([\d\-\,]*)\]?', args.nodes).groups(0)
    resource_list = []
    if bool(brackets):
        for part in brackets.split(","):
            if "-" in part:
                lo, hi = part.split("-")
                assert len(lo) == 4, "expecting number width of 4"
                assert len(hi) == 4, "expecting number width of 4"
                for i in range(int(lo), int(hi) + 1):
                    resource_list.append(f"{resource_name}{i:04d}")
            else:
                assert len(part) == 4, "expecting number width of 4"
                resource_list.append(f"{resource_name}{part}")
    else:
        resource_list.append(resource_name)
        resource_name = resource_name[:-4]
    
    subscription_id = azutil.get_subscription_id()
    resource_group = config["resource_group"]

    vm_ids = []
    nic_ids = []
    disk_ids = []
    for resource in resource_list:
        vm_ids.append(f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Compute/virtualMachines/{resource}")
        nic_ids.append(f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Network/networkInterfaces/{resource}_nic")
        disk_ids.append(f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Compute/disks/{resource}_osdisk")

    # delete vms
    log.debug("deleting vms: "+",".join(vm_ids))
    azutil.delete_resources(vm_ids)
    # delete nics and disks
    log.debug("deleting nics and disks: "+",".join(nic_ids + disk_ids))
    azutil.delete_resources(nic_ids + disk_ids)
    log.debug("exiting do_slurm_suspend")

def do_slurm_resume(args):
    log.debug(f"reading config file ({args.config_file})")
    while True:
        timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        tmpdir = "azhpc_install_" + os.path.basename(args.config_file)[:-5] + "_" + timestamp
        if not os.path.isdir(tmpdir):
            break
        log.warning(f"{tmpdir} already exists, sleeping for 5 seconds and retrying")
        time.sleep(5)
    log.debug(f"tmpdir = {tmpdir}")

    c = azconfig.ConfigFile()
    c.open(args.config_file)
    config = c.preprocess()

    adminuser = config["admin_user"]
    private_key_file = adminuser+"_id_rsa"
    public_key_file = adminuser+"_id_rsa.pub"

    log.info(f"slurm resume for {args.nodes}")
    # first get the resource name
    all_resources = config.get("resources", [])
    resource_name, brackets = re.search(r'([^[]*)\[?([\d\-\,]*)\]?', args.nodes).groups(0)
    resource_list = []
    if bool(brackets):
        for part in brackets.split(","):
            if "-" in part:
                lo, hi = part.split("-")
                assert len(lo) == 4, "expecting number width of 4"
                assert len(hi) == 4, "expecting number width of 4"
                for i in range(int(lo), int(hi) + 1):
                    resource_list.append(f"{resource_name}{i:04d}")
            else:
                assert len(part) == 4, "expecting number width of 4"
                resource_list.append(f"{resource_name}{part}")
    else:
        resource_list.append(resource_name)
        resource_name = resource_name[:-4]
    
    template_resource = config.get("resources", {}).get(resource_name)
    if not template_resource:
        log.error(f"${res} resource not found in config")
        sys.exit(1)
    if template_resource.get("type") != "slurm_partition":
        log.error(f"invalid resource type for scaling")
    
    template_resource["type"] = "vm"
    del template_resource["instances"]

    log.info(f"resource_name= {resource_name}")
    log.info("resource_list= " + ",".join(resource_list))
    
    config["resources"] = {}
    for rname in resource_list:
        config["resources"][rname] = template_resource

    tpl = arm.ArmTemplate()
    tpl.read_resources(config, False)

    output_template = f"deploy_{args.config_file}_{timestamp}"

    log.info("writing out arm template to " + output_template)
    with open(output_template, "w") as f:
        f.write(tpl.to_json())

    log.info("deploying arm template")
    deployname = azutil.deploy(
        config["resource_group"],
        output_template
    )
    log.debug(f"deployment name: {deployname}")

    _wait_for_deployment(config["resource_group"], deployname)
    
    log.info("building host lists")
    azinstall.generate_hostlists(config, tmpdir)
    log.info("building install scripts")
    azinstall.generate_install(config, tmpdir, adminuser, private_key_file, public_key_file)
    
    jumpbox = c.read_value("install_from")
    resource_group = c.read_value("resource_group")
    fqdn = c.get_install_from_destination()
    log.debug(f"running script from : {fqdn}")
    azinstall.run(config, tmpdir, adminuser, private_key_file, public_key_file, fqdn)

def do_build(args):
    log.debug(f"reading config file ({args.config_file})")
    tmpdir = "azhpc_install_" + os.path.basename(args.config_file)[:-5]
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
    _create_private_key(private_key_file, public_key_file)

    tpl = arm.ArmTemplate()
    tpl.read(config, not args.no_vnet)

    output_template = "deploy_"+args.config_file

    log.info("writing out arm template to " + output_template)
    with open(output_template, "w") as f:
        f.write(tpl.to_json())

    log.info("creating resource group " + config["resource_group"])

    resource_tags = config.get("resource_tags", {})
    azutil.create_resource_group(
        config["resource_group"],
        config["location"],
        [
            {
                "key": "CreatedBy",
                "value": os.getenv("USER")
            },
            {
                "key": "CreatedOn",
                "value": datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
            }
        ] + [ { "key": key, "value": resource_tags[key] } for key in resource_tags.keys() ]
    )
    log.info("deploying arm template")
    deployname = azutil.deploy(
        config["resource_group"],
        output_template
    )
    log.debug(f"deployment name: {deployname}")

    _wait_for_deployment(config["resource_group"], deployname)
    
    log.info("building host lists")
    azinstall.generate_hostlists(config, tmpdir)
    log.info("building install scripts")
    azinstall.generate_install(config, tmpdir, adminuser, private_key_file, public_key_file)
    
    resource_group = c.read_value("resource_group")
    fqdn = c.get_install_from_destination()
    log.debug(f"running script from : {fqdn}")
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
        "--debug", 
        help="increase output verbosity",
        action="store_true"
    )
    gopt_parser.add_argument(
        "--no-color", 
        help="turn off color in output",
        action="store_true"
    )

    subparsers = azhpc_parser.add_subparsers(help="actions")

    build_parser = subparsers.add_parser(
        "build", 
        parents=[gopt_parser],
        add_help=False,
        description="deploy the config",
        help="create an arm template and deploy"
    )
    build_parser.add_argument(
        "--no-vnet", 
        action="store_true",
        default=False,
        help="do not create vnet resources in the arm template"
    )
    build_parser.set_defaults(func=do_build)

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

    init_parser = subparsers.add_parser(
        "init",
        parents=[gopt_parser],
        add_help=False,
        description="initialise a project",
        help="copy a file or directory with config files"
    )
    init_parser.set_defaults(func=do_init)
    init_parser.add_argument(
        "--show", 
        "-s", 
        action="store_true",
        default=False,
        help="display all vars that are <NOT-SET>"
    )
    init_parser.add_argument(
        "--dir", 
        "-d", 
        type=str,
        help="output directory",
    )
    init_parser.add_argument(
        "--vars", 
        "-v", 
        type=str,
        help="variables to replace in format VAR=VAL(,VAR=VAL)*",
    )

    preprocess_parser = subparsers.add_parser(
        "preprocess", 
        parents=[gopt_parser],
        add_help=False,
        description="preprocess the config file",
        help="expand all the config macros"
    )
    preprocess_parser.set_defaults(func=do_preprocess)

    run_parser = subparsers.add_parser(
        "run", 
        parents=[gopt_parser],
        add_help=False,
        description="run a command on the specified resources",
        help="run command on resources"
    )
    run_parser.set_defaults(func=do_run)
    run_parser.add_argument(
        "--user", 
        "-u", 
        type=str,
        help="the user to run as"
    )
    run_parser.add_argument(
        "--nodes", 
        "-n", 
        type=str,
        help="the resources to run on (space separated for multiple)"
    )
    run_parser.add_argument(
        'args', 
        nargs=argparse.REMAINDER,
        help="the command to run"
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
        help="the arguments passed to scp (use '--' to separate scp arguments)"
    )

    status_parser = subparsers.add_parser(
        "status", 
        parents=[gopt_parser],
        add_help=False,
        description="show status of all the resources",
        help="displays the resource uptime"
    )
    status_parser.set_defaults(func=do_status)

    slurm_resume_parser = subparsers.add_parser(
        "slurm_resume",
        parents=[gopt_parser],
        add_help=False,
        help="resume VMs for slurm"
    )
    slurm_resume_parser.add_argument(
        "nodes",
        type=str,
        help="the nodes in the slurm array format"
    )
    slurm_resume_parser.set_defaults(func=do_slurm_resume)

    slurm_suspend_parser = subparsers.add_parser(
        "slurm_suspend",
        parents=[gopt_parser],
        add_help=False,
        help="suspend VMs for slurm"
    )
    slurm_suspend_parser.add_argument(
        "nodes",
        type=str,
        help="the nodes in the slurm array format"
    )
    slurm_suspend_parser.set_defaults(func=do_slurm_suspend)

    args = azhpc_parser.parse_args()


    if args.debug:
        azlog.setDebug(True)
    if args.no_color:
        azlog.setColor(False)

    log.debug(args)
    
    args.func(args)

