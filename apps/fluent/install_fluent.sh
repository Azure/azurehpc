#!/bin/bash

install_dir=/apps

#NOTE!!: Update the path to the fluent install file before running the script
inst=/path/to/fluent_install_file.tar

tmp_dir=/tmp/tmp-fluent

mkdir $tmp_dir
pushd $tmp_dir

echo "Install Fluent"
echo "Installer: $inst"

tar xf $inst

yum groupinstall -y "X Window System"
yum -y install freetype motif.x86_64 mesa-libGLU-9.0.0-4.el7.x86_64

./INSTALL -silent -install_dir $install_dir/ansys_inc -fluent -nohelp -disablerss

# fixes required for fluent 19.3.0 on Hb/Hc VMs
sed -i 's/OMPI_MCA_mca_component_show_load_errors/OMPI_MCA_mca_base_component_show_load_errors/g;s/my_ic_flag="--mca btl self,vader,openib"/#my_ic_flag="--mca btl self,vader,openib"/g' $install_dir/ansys_inc/v193/fluent/fluent19.3.0/multiport/mpi_wrapper/bin/mpirun.fl

popd
rm -rf $tmp_dir
