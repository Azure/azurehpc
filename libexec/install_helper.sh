#!/bin/bash

if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "Error: this script should be sourced and not executed"
    exit 1
fi

# constants
pssh_parallelism=50

function create_jumpbox_setup_script()
{
    local tmp_dir="$1"
    local ssh_public_key="$2"
    local ssh_private_key="$3"

    install_sh=$tmp_dir/install/00_install_node_setup.sh
    log_file=install/00_install_node_setup.log

    cat <<OUTER_EOF > $install_sh
#!/bin/bash

# expecting to be in $tmp_dir
cd "\$( dirname "\${BASH_SOURCE[0]}" )/.."

tag=linux

if [ "\$1" != "" ]; then
    tag=tags/\$1
else
    sudo yum install -y epel-release > $log_file 2>&1
    sudo yum install -y pssh nc >> $log_file 2>&1

    # setting up keys
    cat <<EOF > ~/.ssh/config
    Host *
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
        LogLevel ERROR
EOF
    cp $ssh_public_key ~/.ssh/id_rsa.pub
    cp $ssh_private_key ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/config
    chmod 644 ~/.ssh/id_rsa.pub

fi

prsync -p $pssh_parallelism -a -h hostlists/\$tag ~/$tmp_dir ~ >> $log_file 2>&1
prsync -p $pssh_parallelism -a -h hostlists/\$tag ~/.ssh ~ >> $log_file 2>&1

pssh -p $pssh_parallelism -t 0 -i -h hostlists/\$tag 'echo "AcceptEnv PSSH_NODENUM PSSH_HOST" | sudo tee -a /etc/ssh/sshd_config' >> $log_file 2>&1
pssh -p $pssh_parallelism -t 0 -i -h hostlists/\$tag 'sudo systemctl restart sshd' >> $log_file 2>&1
pssh -p $pssh_parallelism -t 0 -i -h hostlists/\$tag "echo 'Defaults env_keep += \"PSSH_NODENUM PSSH_HOST\"' | sudo tee -a /etc/sudoers" >> $log_file 2>&1
OUTER_EOF

}

function create_jumpbox_script()
{
    local config_file=$1
    local tmp_dir=$2
    local step=$3

    idx=$(($step - 1))
    read_value install_script ".install[$idx].script"

    install_sh=$tmp_dir/install/$(printf %02d $step)_$install_script
    log_file=install/$(printf %02d $step)_${install_script%.sh}.log

    read_value install_tag ".install[$idx].tag"

cat <<OUTER_EOF > $install_sh
#!/bin/bash

# expecting to be in $tmp_dir
cd "\$( dirname "\${BASH_SOURCE[0]}" )/.."

tag=\${1:-$install_tag}

OUTER_EOF

    read_value install_reboot ".install[$idx].reboot" false
    read_value install_sudo ".install[$idx].sudo" false
    install_nfiles=$(jq -r ".install[$idx].copy | length" $config_file)

    install_script_arg_count=$(jq -r ".install[$idx].args | length" $config_file)
    install_command_line=$install_script
    if [ "$install_script_arg_count" -ne "0" ]; then
        for n in $(seq 0 $((install_script_arg_count - 1))); do
            read_value arg ".install[$idx].args[$n]"
            install_command_line="$install_command_line '$arg'"
        done
    fi

    if [ "$install_nfiles" != "0" ]; then
        echo "## copying files" >>$install_sh
        for f in $(jq -r ".install[$idx].copy | @tsv" $config_file); do
            echo "pscp.pssh -p $pssh_parallelism -h hostlists/tags/\$tag $f \$(pwd) >> $log_file 2>&1" >>$install_sh
        done
    fi

    sudo_prefix=
    if [ "$install_sudo" = "true" ]; then
        sudo_prefix=sudo
    fi

    # can run in parallel with pssh
    echo "pssh -p $pssh_parallelism -t 0 -i -h hostlists/tags/\$tag \"cd $tmp_dir; $sudo_prefix scripts/$install_command_line\" >> $log_file 2>&1" >>$install_sh

    if [ "$install_reboot" = "true" ]; then
        cat <<EOF >> $install_sh
pssh -p $pssh_parallelism -t 0 -i -h hostlists/tags/\$tag "sudo reboot" >> $log_file 2>&1
echo "    Waiting for nodes to come back"
sleep 10
for h in \$(<hostlists/tags/\$tag); do
    nc -z \$h 22
    echo "        \$h rebooted"
done
sleep 10
EOF
    fi

}

function create_local_script()
{
    local config_file=$1
    local tmp_dir=$2
    local step=$3

    idx=$(($step - 1))
    read_value install_script ".install[$idx].script"

    install_sh=$tmp_dir/install/$(printf %02d $step)_$install_script
    log_file=install/$(printf %02d $step)_${install_script%.sh}.log

    cat <<OUTER_EOF > $install_sh
#!/bin/bash

# expecting to be in $tmp_dir
cd "\$( dirname "\${BASH_SOURCE[0]}" )/.."

OUTER_EOF

    install_script_arg_count=$(jq -r ".install[$idx].args | length" $config_file)
    install_command_line=$install_script
    if [ "$install_script_arg_count" -ne "0" ]; then
        for n in $(seq 0 $((install_script_arg_count - 1))); do
            read_value arg ".install[$idx].args[$n]"
            install_command_line="$install_command_line '$arg'"
        done
    fi

    echo "scripts/$install_command_line >> $log_file 2>&1" >>$install_sh
}

function create_install_scripts()
{
    # function args
    local config_file="$1"
    local tmp_dir="$2"
    local ssh_public_key="$3"
    local ssh_private_key="$4"
    local ssh_args="$5"
    local admin_user="$6"
    local local_script_dir="$7"
    local fqdn="$8"

    local is_jumpbox_required=0
    local nsteps=$(jq -r ".install | length" $config_file)

    mkdir -p $tmp_dir/install       
    for step in $(seq 0 $nsteps); do
    
        if [ "$step" = "0" ]; then
            
            create_jumpbox_setup_script "$tmp_dir" "$ssh_public_key" "$ssh_private_key"

        else

            idx=$(($step - 1))
            read_value install_script_type ".install[$idx].type" jumpbox_script
            
            if [ "$install_script_type" = "jumpbox_script" ]; then
                is_jumpbox_required=1
            
                create_jumpbox_script "$config_file" "$tmp_dir" "$step"

            elif [ "$install_script_type" = "local_script" ]; then

                create_local_script "$config_file" "$tmp_dir" "$step"

            else

                echo "Error: unrecognised script type - $install_script_type"

            fi

        fi 

    done

    chmod +x $tmp_dir/install/*.sh
    cp $ssh_private_key $tmp_dir
    cp $ssh_public_key $tmp_dir
    cp -r $azhpc_dir/scripts $tmp_dir
    cp -r $local_script_dir/* $tmp_dir/scripts/. 2>/dev/null
    
    if [ "$is_jumpbox_required" = "1" ]; then
        rsync -a -e "ssh $ssh_args -i $ssh_private_key" $tmp_dir $admin_user@$fqdn:.
    fi

}

function run_install_scripts()
{
    # function args
    local config_file="$1"
    local tmp_dir="$2"
    local ssh_private_key="$3"
    local ssh_args="$4"
    local admin_user="$5"
    local local_script_dir="$6"
    local fqdn="$7"
    local vmss_resized="$8"

    local run_tag=
    if [ "$vmss_resized" != "" ]; then
        run_tag=$vmss_resized.added
    fi

    local nsteps=$(jq -r ".install | length" $config_file)

    local is_jumpbox_required=0
    for idx in $(seq 0 $(($nsteps - 1))); do
        read_value install_script_type ".install[$idx].type" jumpbox_script
        if [ "$install_script_type" = "jumpbox_script" ]; then
            is_jumpbox_required=1
        fi
    done

    script_error=0
    for step in $(seq 0 $nsteps); do

        # skip jumpbox setup if no jumpbox scripts are required
        if [ "$is_jumpbox_required" = "0" ]; then
            continue
        fi

        idx=$(($step - 1))

        if [ "$step" = "0" ]; then
            install_script=install_node_setup.sh
            install_script_type=jumpbox_script
        else
            read_value install_script ".install[$idx].script"
            read_value install_script_type ".install[$idx].type" jumpbox_script
        fi

        if [ "$vmss_resized" != "" -a "$idx" != "-1" ]; then
            
            if [ "$install_script_type" != "jumpbox_script" ]; then
                status "skipping step $step as it doesn't apply to $vmss_resized"
                continue
            fi

            read_value install_tag ".install[$idx].tag"
            resource_has_tag=$(jq ".resources.$vmss_resized.tags | index(\"$install_tag\")" $config_file)
            if [ "$resource_has_tag" = "null" ]; then
                status "skipping step $step as it doesn't apply to $vmss_resized"
                continue
            fi

        fi

        install_sh=$tmp_dir/install/$(printf %02d $step)_$install_script

        echo "Step $step : $install_script ($install_script_type)"
        start_time=$SECONDS

        if [ "$install_script_type" = "jumpbox_script" ]; then

            host_tag=$run_tag
            if [ "$host_tag" = "" ]; then
                if [ "$idx" = "-1" ]; then
                    host_tag=../linux
                else
                    read_value host_tag ".install[$idx].tag"
                fi
            fi
            nhosts=$(wc -l <$tmp_dir/hostlists/tags/$host_tag)
            
            if [ "$nhosts" = "0" ]; then
                status "skipping step $step as hostlist is empty ($host_tag)"
            else
                ssh $ssh_args -i $ssh_private_key $admin_user@$fqdn $install_sh $run_tag
                exit_code=$?
                if [ "$exit_code" -ne "0" ]; then
                    echo "Error: ($exit_code) Errors while running $install_sh"
                    script_error=1
                    break
                fi
            fi

        elif [ "$install_script_type" = "local_script" ]; then

            $install_sh
            exit_code=$?
            if [ "$exit_code" -ne "0" ]; then
                echo "Error: ($exit_code) Errors while running $install_sh"
                script_error=1
                break
            fi

        else

            echo "Error: unrecognised script type - $install_script_type"

        fi

        echo "    duration: $(($SECONDS - $start_time)) seconds"

    done

    if [ "$is_jumpbox_required" = "1" ]; then
        rsync -a -e "ssh $ssh_args -i $ssh_private_key" $admin_user@$fqdn:$tmp_dir/install/*.log $tmp_dir/install/.
    fi

    if [ "$script_error" -ne "0" ]; then
        error "There were errors while running scripts, exiting"
    fi
}

function build_hostlists
{
    # function args
    local config_file="$1"
    local tmp_dir="$2"

    rm -rf $tmp_dir/hostlists
    mkdir -p $tmp_dir/hostlists/tags
    for resource_name in $(jq -r ".resources | keys | @tsv" $config_file); do

        read_value resource_type ".resources.$resource_name.type"

        if [ "$resource_type" = "vmss" ]; then

            az vmss list-instances \
                --resource-group $resource_group \
                --name $resource_name \
                --query [].osProfile.computerName \
                --output tsv \
                > $tmp_dir/hostlists/$resource_name

            for tag in $(jq -r ".resources.$resource_name.tags | @tsv" $config_file); do
                cat $tmp_dir/hostlists/$resource_name >> $tmp_dir/hostlists/tags/$tag
            done

            cat $tmp_dir/hostlists/$resource_name >> $tmp_dir/hostlists/linux

        elif [ "$resource_type" = "vm" ]; then
            # only get ip for passwordless nodes
            read_value resource_password ".resources.$resource_name.password" "<no-password>"
            
            az vm show \
                --resource-group $resource_group \
                --name $resource_name \
                --query osProfile.computerName \
                --output tsv \
                > $tmp_dir/hostlists/$resource_name

            for tag in $(jq -r ".resources.$resource_name.tags | @tsv" $config_file); do
                cat $tmp_dir/hostlists/$resource_name >> $tmp_dir/hostlists/tags/$tag
            done

            if [ "$resource_password" = "<no-password>" ]; then
                cat $tmp_dir/hostlists/$resource_name >> $tmp_dir/hostlists/linux
            fi
        fi

    done
}
