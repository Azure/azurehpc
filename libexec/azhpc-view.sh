#!/bin/bash
export azhpc_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$azhpc_dir/libexec/common.sh"

DEBUG_ON=0
COLOR_ON=1
config_file="config.json"

pssh_parallelism=50

function usage() {
    echo "Command:"
    echo "    $0 [options]"
    echo
    echo "Arguments"
    echo "    -h --help  : diplay this help"
    echo "    -c --config: config file to use"
    echo "                 default: config.json"
    echo
}

while true; do
    case $1 in
        -h|--help)
        usage
        exit 0
        ;;
        -c|--config)
        config_file="$2"
        shift
        shift
        ;;
        *)
        break
    esac
done

if [ ! -f "$config_file" ]; then
    error "missing config file ($config_file)"
fi

read_value vnet_name ".vnet.name"
read_value address_prefix ".vnet.address_prefix"

output_file=diagram.dot

cat <<EOF >$output_file
digraph D {
    subgraph cluster_vnet_$vnet_name {
        rankdir="LR";
        label="$vnet_name [$address_prefix]";
        labeljust="l;"
EOF

debug "looping through subnets"

for subnet_name in $(jq -r ".vnet.subnets | keys | @tsv" $config_file); do
    debug "subnet $subnet_name"
    read_value subnet_address_prefix ".vnet.subnets.$subnet_name"

    cat <<EOF >>$output_file
        subgraph cluster_subnet_$subnet_name {
            label="$subnet_name [$subnet_address_prefix]";
            labeljust="l;"
EOF

    for resource_name in $(jq -r ".resources | to_entries[] | select(.value.subnet==\"$subnet_name\") | .key" config.json ); do 
        read_value resource_type ".resources.$resource_name.type"
        read_value resource_vm_type ".resources.$resource_name.vm_type"
        read_value resource_image ".resources.$resource_name.image"
        read_value resource_pip ".resources.$resource_name.public_ip" false
        read_value resource_an ".resources.$resource_name.accelerated_networking" false
        read_value resource_instances ".resources.$resource_name.instances" 0

        cat <<EOF >>$output_file
            subgraph cluster_$resource_name {
                rank="same";
                edge[style="invisible",dir="none"];
                label="$resource_type: $resource_name\l$resource_vm_type\l$resource_image\l";
EOF
        if [ "$resource_type" = "vm" ]; then
            cat <<EOF >>$output_file
                $resource_name [ label="$resource_name", shape="box" ];
EOF
        elif [ "$resource_type" = "vmss" ]; then
            edges=()
            for n in $(seq -w 1 $resource_instances); do
                edges+=(${resource_name}_$n)
                cat <<EOF >>$output_file
                ${resource_name}_$n [ label="${resource_name}_$n", shape="box" ];
EOF
            done
            if [ "$resource_instances" -gt "1" ]; then
                echo "${edges[@]};" | sed 's/ /->/g' >> $output_file
            fi                
        fi

        cat <<EOF >>$output_file
            }
EOF

        # end of resource loop
    done

# storage loop
for storage_name in $(jq -r ".storage | to_entries[] | select(.value.subnet==\"$subnet_name\") | .key" config.json 2>/dev/null); do 
        read_value storage_type ".storage.$storage_name.type"

        # pool loop
        for pool_name in $(jq -r ".storage.$storage_name.pools | keys | @tsv" config.json ); do 
            read_value pool_size ".storage.$storage_name.pools.$pool_name.size"
            read_value pool_service_level ".storage.$storage_name.pools.$pool_name.service_level"
            cat <<EOF >>$output_file    
            subgraph cluster_${storage_name}_${pool_name} {
                rank="same";
                edge[style="invisible",dir="none"];
                label="$storage_name\l$pool_name\l$pool_size TB [$pool_service_level]\l";
EOF

            edges=()
            # volume loop
            for volume_name in $(jq -r ".storage.$storage_name.pools.$pool_name.volumes | keys | @tsv" config.json ); do 
                read_value volume_size ".storage.$storage_name.pools.$pool_name.volumes.$volume_name.size"
                read_value volume_mount ".storage.$storage_name.pools.$pool_name.volumes.$volume_name.mount"
                cat <<EOF >>$output_file    
                ${storage_name}_${pool_name}_${volume_name} [ label="$volume_name, $volume_size TB [$volume_mount]", shape="box" ];
EOF
                edges+=(${storage_name}_${pool_name}_${volume_name})
                # end of volume loop
            done

            if [ "${#edges[@]}" -gt "1" ]; then
                echo "${edges[@]};" | sed 's/ /->/g' >> $output_file
            fi    


            cat <<EOF >>$output_file
            }
EOF

            # end of pool loop
        done

        # end of storage loop
    done

    cat <<EOF >>$output_file
        }
EOF

    # end of subnet loop
done


cat <<EOF >>$output_file
    }
}
EOF

debug "written $output_file"
if [ "$(which dot)" = "" ]; then
    warning "cannot create image as 'dot' is not available (install graphviz package)"
    exit 1
fi

dot -Tpng $output_file >diagram.png
status "written diagram.png"

if [ "$DO_INSTALL_DIAGRAM" = "" ]; then
    exit 0
fi



function make_dot_name() {
    dot_name=$(sed 's/-/_/g;s/\./_/g' <<< $1)
}

resource_to_tags=()
tags_to_script=()

output_file=install.dot

cat <<EOF >$output_file
digraph D {
    splines=false;
    rank="LR";
    nodesep=0.25;
EOF

cat <<EOF >>$output_file
    subgraph cluster_resources {
        margin=50;
        label="Resources";
        rank="same";
        edge[style="invisible",dir="none"];
EOF
resource_dot_names=()
for resource_name in $(jq -r '.resources | keys | @tsv' config.json); do
    make_dot_name $resource_name
    cat <<EOF >>$output_file
        resource_$dot_name [ label="$resource_name", shape="box", width=3 ];
EOF
    resource_dot_names+=(resource_$dot_name)
    resource_dot_name=resource_$dot_name
    for tag in $(jq -r ".resources.$resource_name.tags | @tsv" config.json); do
        make_dot_name $tag
        resource_to_tags+=("$resource_dot_name:e -> $dot_name:w")
    done
done

if [ "${#resource_dot_names[@]}" -gt "1" ]; then
    echo "${resource_dot_names[@]};" | sed 's/ /->/g' >> $output_file
fi
cat <<EOF >>$output_file
    }
EOF

cat <<EOF >>$output_file
    subgraph cluster_tags {
        margin=50;
        label="Tags";
        rank="same";
        edge[style="invisible",dir="none"];
EOF
tag_dot_names=()
#for tag_name in $(jq -r "[.resources[].tags[]] | unique | @tsv" config.json); do
for tag_name in $(jq -r ".install[].tag" config.json); do
    make_dot_name $tag_name
    tag_dot_names+=($dot_name)
    cat <<EOF >>$output_file
        $dot_name [ label="$tag_name", shape="box", width=3 ];
EOF
done

if [ "${#tag_dot_names[@]}" -gt "1" ]; then
    echo "${tag_dot_names[@]};" | sed 's/ /->/g' >> $output_file
fi

cat <<EOF >>$output_file
    }
EOF


cat <<EOF >>$output_file
    subgraph cluster_install {
        margin=50;
        label="Install Steps"
EOF
install_steps=$(jq -r '.install | length' config.json)
for install_step in $(seq 0 $(( $install_steps - 1 )) ); do
    read_value script_name ".install[$install_step].script"
    cat <<EOF >>$output_file
        step$install_step [ label="Step $(($install_step + 1)): $script_name", shape="box", width=3 ];
EOF
    read_value tag_name ".install[$install_step].tag"
    make_dot_name $tag_name
    tags_to_script+=("$dot_name:e -> step$install_step:w")
done
cat <<EOF >>$output_file
    }
EOF

# resource to tag arrows
for edge in "${resource_to_tags[@]}"; do
    cat <<EOF >>$output_file
    $edge [constraint=false];
EOF
done

# tag to script arrows
for edge in "${tags_to_script[@]}"; do
    cat <<EOF >>$output_file
    $edge [constraint=false];
EOF
done

# install step arrows
if [ "$install_steps" -gt "1" ]; then
    for install_step in $(seq 1 $(( $install_steps - 1 )) ); do
        cat <<EOF >>$output_file
    step$(($install_step - 1)) -> step$install_step;
EOF
    done
fi

cat <<EOF >>$output_file
}
EOF

dot -Tpng $output_file >install.png
status "written install.png"
