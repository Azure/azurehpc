import json
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

def _make_subprocess_error_string(res):
    return "\n    args={}\n    return code={}\n    stdout={}\n    stderr={}".format(res.args, res.returncode, res.stdout.decode("utf-8"), res.stderr.decode("utf-8"))

def create_jumpbox_setup_script(tmpdir, sshprivkey, sshpubkey):
    scriptfile = f"{tmpdir}/install/00_install_node_setup.sh"
    logfile = "install/00_install_node_setup.log"

    with open(scriptfile, "w") as f:
        os.chmod(scriptfile, 0o755)
        f.write(f"""#!/bin/bash

cd "$( dirname "${{BASH_SOURCE[0]}}" )/.."

tag=linux

if [ ! -f "hostlists/$tag" ]; then
    echo "no hostlist ($tag), exiting"
    exit 0
fi

if [ "$1" != "" ]; then
    tag=tags/$1
else
    retry=0
    while ! rpm -q epel-release
    do
        if ! sudo yum install -y epel-release >> {logfile} 2>&1
        then
            if [ "$retry" -eq "10" ]; then
                echo "ERROR: Unable to install epel-release package after 10 retries"
                exit 1
            fi
            sleep 10
            sudo yum clean metadata
            retry=$(($retry + 1))
        fi
    done
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

# check sshd is up on all nodes
for h in $(<hostlists/$tag); do
    retry=0
    until ssh $h hostname >/dev/null 2>&1; do
        if [ "$retry" -eq "10" ]; then
            echo "ERROR: Unable to contact $h after 10 retries"
            exit 1
        fi
        echo "Waiting for sshd on host - $h (sleeping for 10 seconds)"
        sleep 10
        retry=$(($retry + 1))
    done
done

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

    marker = f"marker-\"'$(hostname)'\"-{step:02}-{targetscript[:targetscript.rfind('.')]}"

    content += f"pssh -p {pssh_threads} -t 0 -i -h hostlists/tags/$tag \"cd {tmpdir}; test -f {marker} && echo 'script already run' || ( {cmdline} && ( touch {marker} || true ) ) \" >> {logfile} 2>&1\n"

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
    script_end = ""
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
echo "{ip}:/{volume} {mount_point} nfs bg,rw,hard,noatime,nolock,rsize=65536,wsize=65536,vers=3,tcp,_netdev 0 0" >>/etc/fstab
"""
                script_end += f"""
chmod 777 {mount_point}
"""
    script += f"""
mount -a
{script_end}
"""
    with open(scriptfile, "w") as f:
        os.chmod(scriptfile, 0o755)
        f.write(script) 

def __config_has_netapp(cfg):
    for r in cfg.get("storage", {}).keys():
        if cfg["storage"][r].get("type", "") == "anf":
            return True
    return False

def __copy_script(name, dest):
    # this looks for the script locally first, else in $azhpc_dir/scripts
    if os.path.exists(f"scripts/{name}"):
        if os.path.isdir(f"scripts/{name}"):
            log.debug(f"using dir from this project ({name})")
            shutil.copytree(f"scripts/{name}", f"{dest}/{name}")
        else:
            log.debug(f"using script from this project ({name})")
            shutil.copy(f"scripts/{name}", dest)
    elif os.path.exists(f"{os.getenv('azhpc_dir')}/scripts/{name}"):
        if os.path.isdir(f"{os.getenv('azhpc_dir')}/scripts/{name}"):
            log.debug(f"using azhpc dir ({name})")
            shutil.copytree(f"{os.getenv('azhpc_dir')}/scripts/{name}", f"{dest}/{name}")
        else:
            log.debug(f"using azhpc script ({name})")
            shutil.copy(f"{os.getenv('azhpc_dir')}/scripts/{name}", dest)
    else:
        log.error(f"cannot find scripts/dir ({name})")
        sys.exit(1)


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

    # Add library script to the destination
    __copy_script("azhpc-library.sh", f"{tmpdir}/scripts")
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
            __copy_script(script, f"{tmpdir}/scripts")

def __cyclecloud_upload_project(project_dir):
    cyclecloud_exe = shutil.which("cyclecloud")
    if cyclecloud_exe is None:
        cyclecloud_exe = os.path.join(os.environ["HOME"], "bin", "cyclecloud")
        if not os.path.isfile(cyclecloud_exe):
            log.error("cyclecloud cli not found")
            sys.exit(1)

    env = os.environ.copy()
    if env.get("PYTHONPATH"):
        del env["PYTHONPATH"]

    cmd = [ cyclecloud_exe, "project", "default_locker", "azure-storage" ]
    res = subprocess.run(cmd, cwd=project_dir, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        log.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)
    
    cmd = [ cyclecloud_exe, "project", "upload" ]
    res = subprocess.run(cmd, cwd=project_dir, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        log.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)

def generate_cc_projects(config, tmpdir):
    # create projects in filesystem with the following structure:
    #
    #   <project-name>_<project-version>
    #   ├── project.ini
    #   ├── specs
    #   │   ├── <spec-name>
    #   │     └── cluster-init
    #   │        ├── scripts
    #   │        ├── files 
    #
    # Azurehpc scripts will be put in the files directory and the scripts
    # will be generated to call azurehpc scripts with the correct args.
    for p in config.get("cyclecloud",{}).get("projects", {}):
        pl = p.split(":")
        if len(pl) != 3:
            log.error(f"cannot parse cyclecloud project name - {p}.  Format should be PROJECT:SPEC:VERSION.")
            sys.exit(1)
        project, spec, version = pl
        project_dir = f"{tmpdir}/{project}_{version}"
        
        if not os.path.exists(project_dir):
            # create directory and project.ini file
            os.makedirs(project_dir)
            project_ini = f"""[project]
version = {version}
type = application
name = {project}
"""
            with open(f"{project_dir}/project.ini", "w") as f:
                f.write(project_ini)

        spec_dir = f"{project_dir}/specs/{spec}"
        scripts_dir = f"{spec_dir}/cluster-init/scripts"
        files_dir = f"{spec_dir}/cluster-init/files"
        os.makedirs(scripts_dir)
        os.makedirs(files_dir)

        for idx, step in enumerate(config["cyclecloud"]["projects"][p]):
            script = step["script"]
            script_file = f"{scripts_dir}/{idx:02d}_{script}"
            background = step.get("background", None)

            # copy script file and dependencies into files_dir
            for s in [ script ] + step.get("deps", []):
                __copy_script(s, files_dir)

            # create cluster-init script
            args = " ".join([ f'"{arg}"' for arg in step.get("args", []) ])
            if background:
               script_content = f"""#!/bin/bash
chmod +x $CYCLECLOUD_SPEC_PATH/files/*.sh
$CYCLECLOUD_SPEC_PATH/files/{script} {args} &
"""
            else:
               script_content = f"""#!/bin/bash
chmod +x $CYCLECLOUD_SPEC_PATH/files/*.sh
$CYCLECLOUD_SPEC_PATH/files/{script} {args}
"""
            with open(script_file, "w") as f:
                os.chmod(script_file, 0o755)
                f.write(script_content)
        
        log.info(f"uploading project ({project_dir})")
        __cyclecloud_upload_project(project_dir)

def __cyclecloud_create_cluster(template, name, paramfile):
    cyclecloud_exe = os.path.join(os.environ["HOME"], "bin", "cyclecloud")
    cmd = [
        cyclecloud_exe, "create_cluster", template, name,
        "-p", paramfile, "--force"
    ]

    env = os.environ.copy()
    if env.get("PYTHONPATH"):
        del env["PYTHONPATH"]

    res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        log.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)

def __cyclecloud_import_cluster(template, name, paramfile, tmpdir):
    cyclecloud_exe = os.path.join(os.environ["HOME"], "bin", "cyclecloud")
    template_type = template.split("_")[0]
    log.debug(f"template_type = {template_type}")
    shutil.copy(template, tmpdir)
    template = os.path.join(tmpdir,template)
    log.debug(f"template={template}")
    cmd = [
           cyclecloud_exe, "import_cluster", name, "-c", template_type, "-f", template,
        "-p", paramfile, "--force"
    ]

    env = os.environ.copy()
    if env.get("PYTHONPATH"):
        del env["PYTHONPATH"]

    res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        log.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)

def generate_cc_clusters(config, tmpdir):
    os.makedirs(tmpdir)
    for cluster_name in config.get("cyclecloud",{}).get("clusters", {}):
        log.info(f"creating cluster {cluster_name}")
        cluster_template = config["cyclecloud"]["clusters"][cluster_name]["template"]
        cluster_params = config["cyclecloud"]["clusters"][cluster_name]["parameters"]
        cluster_json = f"{tmpdir}/{cluster_name}.json"
        with open(cluster_json, "w") as f:
            f.write(json.dumps(cluster_params, indent=4))
        if os.path.isfile(cluster_template):
           __cyclecloud_import_cluster(cluster_template, cluster_name, cluster_json, tmpdir)
        else:
           __cyclecloud_create_cluster(cluster_template, cluster_name, cluster_json)
        
def __rsync(sshkey, sshport, src, dst):
    cmd = [
        "rsync", "-a", "--timeout=60", "-e",
            f"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p {sshport} -i {sshkey}",
            src, dst
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        log.error("invalid returncode"+_make_subprocess_error_string(res))
        sys.exit(1)

def run(cfg, tmpdir, adminuser, sshprivkey, sshpubkey, fqdn, startstep=0):
    jb = cfg.get("install_from")
    sshport = cfg.get("ssh_port", 22)
    install_steps = [{ "script": "install_node_setup.sh" }] + cfg.get("install", [])
    if jb:
        log.debug("wait for ssh on jumpbox")
        attempt = 1
        while True:
            cmd = [
                "ssh", 
                    "-o", "StrictHostKeyChecking=no",
                    "-o", "UserKnownHostsFile=/dev/null",
                    "-p", str(sshport),
                    "-i", sshprivkey,
                    f"{adminuser}@{fqdn}",
                    "hostname"
            ]
            res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if res.returncode == 0:
                break

            attempt += 1
            if attempt > 10:
                log.error("failed to connect to the jumpbox after 10 attempts")
                sys.exit(1)
            
            time.sleep(10)
            
        log.debug("rsyncing install files")
        __rsync(sshprivkey, sshport, tmpdir, f"{adminuser}@{fqdn}:.")

    for idx, step in enumerate(install_steps):
        if idx == 0 and not jb:
            continue

        script = step["script"]
        scripttype = step.get("type", "jumpbox_script")
        instcmd = [ f"{tmpdir}/install/{idx:02}_{script}" ]
        log.info(f"Step {idx:02} : {script} ({scripttype})")
        starttime = time.time()

        if idx != 0 and idx < startstep:
            log.info("    skipping step")
            continue

        if scripttype == "jumpbox_script":
            if jb:
                tag = step.get("tag", None)
                if tag:
                    instcmd.append(tag)

                cmd = [
                    "ssh", 
                        "-o", "StrictHostKeyChecking=no",
                        "-o", "UserKnownHostsFile=/dev/null",
                        "-p", str(sshport),
                        "-i", sshprivkey,
                        f"{adminuser}@{fqdn}"
                ] + instcmd
                res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                if res.returncode != 0:
                    log.error("invalid returncode"+_make_subprocess_error_string(res))
                    __rsync(sshprivkey, sshport, f"{adminuser}@{fqdn}:{tmpdir}/install/*.log", f"{tmpdir}/install/.")
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
            __rsync(sshprivkey, sshport, f"{adminuser}@{fqdn}:{tmpdir}/install/*.log", f"{tmpdir}/install/.")
        
