#!/bin/bash

BEEGFS_AZHPC_SCRIPTS=beegfspkgs.sh,beegfsc.sh
PROJECT_DIR=cycle_projects

cd $HOME

if [ ! -d $PROJECT_DIR ]; then
mkdir $PROJECT_DIR
fi
pushd $PROJECT_DIR

if [ ! -d "azhpc" ]; then
cat << EOF | cyclecloud project init azhpc
azure-storage

EOF
fi

pushd azhpc

spec=default
eval cp -r $HOME/scripts/{$BEEGFS_AZHPC_SCRIPTS} specs/$spec/cluster-init/files/.

cat <<EOF >specs/$spec/cluster-init/scripts/01-$spec.sh
#!/bin/bash
chmod +x \$CYCLECLOUD_PROJECT_PATH/default/files/*.sh
EOF
chmod +x specs/$spec/cluster-init/scripts/01-$spec.sh

spec=beegfs-client
cyclecloud project add_spec $spec

cat <<EOF >specs/$spec/cluster-init/scripts/01-$spec.sh
#!/bin/bash

beegfs_mgmthost=\$(jetpack config beegfs.mgmt_host)

. \$CYCLECLOUD_PROJECT_PATH/default/files/beegfspkgs.sh
. \$CYCLECLOUD_PROJECT_PATH/default/files/beegfsc.sh \$beegfs_mgmthost

EOF
chmod +x specs/$spec/cluster-init/scripts/01-$spec.sh

cyclecloud project upload

popd
popd
