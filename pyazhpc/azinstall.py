import os
import re
import shutil
import subprocess
import sys
import time

import azlog
import azutil

log = azlog.getLogger(__name__)

pssh_threads = 50

def create_jumpbox_setup_script(tmpdir, sshprivkey, sshpubkey):
    scriptfile = f"{tmpdir}/install/00_install_node_setup.sh"
    logfile = "install/00_install_node_setup.log"

    with open(scriptfile, "w") as f:
        os.chmod(scriptfile, 0o755)
        f.write(f"""#!/bin/bash

cd "$( dirname "${{BASH_SOURCE[0]}}" )/.."

tag=linux

# wait for DNS to update for all hostnames
for h in $(<hostlists/$tag); do
    until host $h >/dev/null 2>&1; do
        echo "Waiting for host - $h (sleeping for 5 seconds)"
        sleep 5
    done
done

if [ "$1" != "" ]; then
    tag=tags/$1
else
    sudo yum install -y epel-release > {logfile} 2>&1
    sudo yum install -y pssh nc >> {logfile} 2>&1

    # setting up keys
    cat <<EOF > ~/.ssh/config
    Host *
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
        LogLevel ERROR
EOF
    cp {sshpubkey} ~/.ssh/id_rsa.pub
    cp {sshprivkey} ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/config
    chmod 644 ~/.ssh/id_rsa.pub

fi

pssh -p {pssh_threads} -t 0 -i -h hostlists/$tag 'rpm -q rsync || sudo yum install -y rsync' >> {logfile} 2>&1

prsync -p {pssh_threads} -a -h hostlists/$tag ~/{tmpdir} ~ >> {logfile} 2>&1
prsync -p {pssh_threads} -a -h hostlists/$tag ~/.ssh ~ >> {logfile} 2>&1

pssh -p {pssh_threads} -t 0 -i -h hostlists/$tag 'echo "AcceptEnv PSSH_NODENUM PSSH_HOST" | sudo tee -a /etc/ssh/sshd_config' >> {logfile} 2>&1
pssh -p {pssh_threads} -t 0 -i -h hostlists/$tag 'sudo systemctl restart sshd' >> {logfile} 2>&1
pssh -p {pssh_threads} -t 0 -i -h hostlists/$tag "echo 'Defaults env_keep += \\"PSSH_NODENUM PSSH_HOST\\"' | sudo tee -a /etc/sudoers" >> {logfile} 2>&1
""")

def create_jumpbox_script(inst, tmpdir, step):
    targetscript = inst["script"]
    scriptfile = f"{tmpdir}/install/{step:02}_{targetscript}"
    logfile = f"install/{step:02}_{targetscript[:targetscript.rfind('.')]}.log"
    tag = inst["tag"]
    content = f"""#!/bin/bash

# expecting to be in $tmp_dir
cd "$( dirname "${{BASH_SOURCE[0]}}" )/.."

tag=${{1:-{tag}}}

if [ ! -f "hostlists/tags/$tag" ]; then
    echo "    Tag is not assigned to any resource (not running)"
    exit 0
fi

if [ "$(wc -l < hostlists/tags/$tag)" = "0" ]; then
    echo "    Tag does not contain any resources (not running)"
    exit 0
fi

"""
    reboot = inst.get("reboot", False)
    sudo = inst.get("sudo", False)
    files = inst.get("copy", [])
    args = inst.get("args", [])

    for f in files:
        content += f"pscp.pssh -p {pssh_threads} -h hostlists/tags/$tag {f} $(pwd) >> {logfile} 2>&1\n"

    cmdline = " ".join([ "scripts/"+targetscript ] + [ f"'{arg}'" for arg in args ])
    if sudo:
        cmdline = "sudo " + cmdline

    content += f"pssh -p {pssh_threads} -t 0 -i -h hostlists/tags/$tag \"cd {tmpdir}; {cmdline}\" >> {logfile} 2>&1\n"

    if reboot:
        content += f"""
pssh -p {pssh_threads} -t 0 -i -h hostlists/tags/$tag "sudo reboot" >> {logfile} 2>&1
echo "    Waiting for nodes to come back"
sleep 10
for h in $(<hostlists/tags/$tag); do
    nc -z $h 22
    echo "        $h rebooted"
done
sleep 10
"""

    with open(scriptfile, "w") as f:
        os.chmod(scriptfile, 0o755)
        f.write(content)

def create_local_script(inst, tmpdir, step):
    targetscript = inst["script"]
    scriptfile = f"{tmpdir}/install/{step:02}_{targetscript}"
    logfile = f"install/{step:02}_{targetscript[:targetscript.rfind('.')]}.log"
    
    args = inst.get("args", [])

    #cmdline = " ".join([ "scripts/"+targetscript ] + [ f"'{arg}'" for arg in args ])
    cmdline = " ".join([ "scripts/"+targetscript ] + [ f'"{arg}"' for arg in args ])
    
    with open(scriptfile, "w") as f:
        os.chmod(scriptfile, 0o755)
        f.write(f"""#!/bin/bash

# expecting to be in $tmp_dir
cd "$( dirname "${{BASH_SOURCE[0]}}" )/.."

{cmdline} >> {logfile} 2>&1

""")

def generate_hostlists(cfg, tmpdir):
    os.makedirs(tmpdir+"/hostlists/tags")
    dns_domain = cfg["vnet"].get("dns_domain", None)
    dns_domain_end = ""
    if dns_domain:
        dns_domain_end = f".{dns_domain}"
    hosts = {}
    tags = {}
    for rname in cfg.get("resources", {}).keys():
        rtype = cfg["resources"][rname]["type"]
        if rtype == "vm":
            instances = cfg["resources"][rname].get("instances", 1)
            if instances == 1:
                hosts[rname] = [ rname ]
            else:
                hosts[rname] = [ f"{rname}{n:04}" for n in range(1, instances+1) ]            
        elif rtype == "vmss":
            hosts[rname] = azutil.get_vmss_instances(cfg["resource_group"], rname)

        for tname in cfg["resources"][rname].get("tags", []):
            # handle partial VMSS for a tag with python [] notation
            p = re.compile("([\w-]+)\[(\d*)([:]?)([-]?[\d]*)\]")
            matches = p.findall(tname)
            if matches:
                m = matches[0]
                lower = 0
                upper = None
                if m[1] != "":
                    lower = int(m[1])
                if m[2] != ":":
                    # single item
                    upper = lower + 1
                else:
                    if m[3] != "":
                        upper = int(m[3])
                log.debug(f"using partial VMSS: name={m[0]}, lower={lower}, upper={upper} (original={tname})")
                tags.setdefault(m[0], []).extend(hosts.get(rname, [])[lower:upper])
            else:
                tags.setdefault(tname, []).extend(hosts.get(rname, []))

        if not cfg["resources"][rname].get("password", None):
            hosts.setdefault("linux", []).extend(hosts.get(rname, []))

    for n in hosts.keys():
        with open(f"{tmpdir}/hostlists/{n}", "w") as f:
            f.writelines(f"{h}{dns_domain_end}\n" for h in hosts[n])
    
    for n in tags.keys():
        with open(f"{tmpdir}/hostlists/tags/{n}", "w") as f:
            f.writelines(f"{h}{dns_domain_end}\n" for h in tags[n])

def _create_anf_mount_scripts(cfg, scriptfile):
    script = """#!/bin/bash
yum install -y nfs-utils
"""
    resource_group = cfg["resource_group"]
    # loop over all anf accounts
    accounts = [ x for x in cfg.get("storage",{}) if cfg["storage"][x]["type"] == "anf" ]
    for account in accounts:
        pools = cfg["storage"][account].get("pools",{}).keys()
        for pool in pools:
            volumes = cfg["storage"][account]["pools"][pool].get("volumes",{}).keys()
            for volume in volumes:
                ip = azutil.get_anf_volume_ip(resource_group, account, pool, volume)
                mount_point = cfg["storage"][account]["pools"][pool]["volumes"][volume]["mount"]
                script += f"""
mkdir -p {mount_point}
chmod 777 {mount_point}
echo "{ip}:/{volume} {mount_point} nfs bg,rw,hard,noatime,nolock,rsize=65536,wsize=65536,vers=3,tcp,_netdev 0 0" >>/etc/fstab
"""
    script += """
mount -a
"""
    with open(scriptfile, "w") as f:
        os.chmod(scriptfile, 0o755)
        f.write(script) 

def __config_has_netapp(cfg):
    for r in cfg.get("storage", {}).keys():
        if cfg["storage"][r].get("type", "") == "anf":
            return True
    return False

def generate_install(cfg, tmpdir, adminuser, sshprivkey, sshpubkey):
    jb = cfg.get("install_from", None)
    os.makedirs(tmpdir+"/install")
    os.makedirs(tmpdir+"/scripts")
    shutil.copy(sshpubkey, tmpdir)
    shutil.copy(sshprivkey, tmpdir)

    if __config_has_netapp(cfg):
        os.makedirs("scripts", exist_ok=True)
        _create_anf_mount_scripts(cfg, "scripts/auto_netappfiles_mount.sh")

    inst = cfg.get("install", [])
    create_jumpbox_setup_script(tmpdir, sshprivkey, sshpubkey)

    for n, step in enumerate(inst):
        stype = step.get("type", "jumpbox_script")
        if stype == "jumpbox_script":
            create_jumpbox_script(step, tmpdir, n+1)
        elif stype == "local_script":
            create_local_script(step, tmpdir, n+1)
        else:
            log.error(f"unrecognised script type ({stype})")
            sys.exit(1)
        
        for script in [ step["script"] ] + step.get("deps", []):
            if os.path.exists(f"scripts/{script}"):
                log.debug(f"using script from this project ({script})")
                shutil.copy(f"scripts/{script}", tmpdir+"/scripts")
            elif os.path.exists(f"{os.getenv('azhpc_dir')}/scripts/{script}"):
                log.debug(f"using azhpc script ({script})")
                shutil.copy(f"{os.getenv('azhpc_dir')}/scripts/{script}", tmpdir+"/scripts")
            else:
                log.error(f"cannot find script ({script})")
                sys.exit(1)

def _make_subprocess_error_string(res):
    return "\n    args={}\n    return code={}\n    stdout={}\n    stderr={}".format(res.args, res.returncode, res.stdout.decode("utf-8"), res.stderr.decode("utf-8"))

def __rsync(sshkey, src, dst):
    cmd = [
        "rsync", "-a", "-e",
            f"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i {sshkey}",
            src, dst
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        log.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)

def run(cfg, tmpdir, adminuser, sshprivkey, sshpubkey, fqdn):
    jb = cfg.get("install_from")
    install_steps = [{ "script": "install_node_setup.sh" }] + cfg.get("install", [])
    if jb:
        log.debug("rsyncing install files")
        __rsync(sshprivkey, tmpdir, f"{adminuser}@{fqdn}:.")

    for idx, step in enumerate(install_steps):
        if idx == 0 and not jb:
            continue
        script = step["script"]
        scripttype = step.get("type", "jumpbox_script")
        instcmd = [ f"{tmpdir}/install/{idx:02}_{script}" ]
        log.info(f"Step {idx:02} : {script} ({scripttype})")
        starttime = time.time()

        if scripttype == "jumpbox_script":
            if jb:
                tag = step.get("tag", None)
                if tag:
                    instcmd.append(tag)

                cmd = [
                    "ssh", 
                        "-o", "StrictHostKeyChecking=no",
                        "-o", "UserKnownHostsFile=/dev/null",
                        "-i", sshprivkey,
                        f"{adminuser}@{fqdn}"
                ] + instcmd
                res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                if res.returncode != 0:
                    log.error("invalid returncode"+_make_subprocess_error_string(res))
                    __rsync(sshprivkey, f"{adminuser}@{fqdn}:{tmpdir}/install/*.log", f"{tmpdir}/install/.")
                    sys.exit(1)
            else:
                log.warning("skipping step as no jumpbox (install_from) is set")

        elif scripttype == "local_script":
            res = subprocess.run(instcmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if res.returncode != 0:
                log.error("invalid returncode"+_make_subprocess_error_string(res))
                sys.exit(1)
        
        else:
            log.error(f"unrecognised script type {scripttype}")

        duration = time.time() - starttime
        log.info(f"    duration: {duration:0.0f} seconds")

        if jb:
            log.debug("rsyncing log files back")
            __rsync(sshprivkey, f"{adminuser}@{fqdn}:{tmpdir}/install/*.log", f"{tmpdir}/install/.")
        
