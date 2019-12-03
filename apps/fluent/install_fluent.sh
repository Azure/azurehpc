#!/bin/bash

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/apps}
TMP_DIR=${TMP_DIR:-/mnt/resource}
FLUENT_INSTALLER_FILE=${FLUENT_INSTALLER_FILE:-/mnt/resource/FLUIDS_2019R3_LINX64.tar}
FLUENT_VERSION=${FLUENT_VERSION:-v195}

if [ ! -e $FLUENT_INSTALLER_FILE ]; then
    echo "Error:  $FLUENT_INSTALLER_FILE does not exist"
    echo "You can set the path to the file with the variable FLUENT_INSTALLER_FILE"
    exit 1
fi

tmp_dir=/tmp/tmp-fluent

mkdir $tmp_dir
cd $tmp_dir

echo "Install Fluent"
echo "Installer: $inst"

tar xf $FLUENT_INSTALLER_FILE

yum groupinstall -y "X Window System"
yum -y install freetype motif.x86_64 mesa-libGLU-9.0.0-4.el7.x86_64

./INSTALL -silent -install_dir $APP_INSTALL_DIR/ansys_inc -fluent -nohelp -disablerss

# fixes required for fluent 19.3.0 on Hb/Hc VMs
sed -i 's/OMPI_MCA_mca_component_show_load_errors/OMPI_MCA_mca_base_component_show_load_errors/g;s/my_ic_flag="--mca btl self,vader,openib"/#my_ic_flag="--mca btl self,vader,openib"/g' $APP_INSTALL_DIR/ansys_inc/$FLUENT_VERSION/fluent/fluent*/multiport/mpi_wrapper/bin/mpirun.fl
sed -i s/-mpiopt=\$PARA_MPIRUN_FLAGS/-mpiopt=\'\$PARA_MPIRUN_FLAGS\'/g  $APP_INSTALL_DIR/ansys_inc/$FLUENT_VERSION/fluent/bin/fluentbench.pl

cd -
rm -rf $tmp_dir
