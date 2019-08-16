#!/bin/bash
GMX_VERSION=2019.3
WORKING_DIR=/mnt/resource
INSTALL_DIR=/apps/gromacs-${GMX_VERSION}

cd ${WORKING_DIR}

setup_build_tools()
{
    echo "Installing Development tools"

    # setup CMAKE
    echo "Installing CMAKE"
    wget -q http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/c/cmake3-3.6.3-1.el7.x86_64.rpm
    wget -q http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
    sudo rpm -Uvh epel-release*rpm
    sudo yum install cmake3 -y
    sudo ln -s /usr/bin/cmake3 /usr/bin/cmake

    # setup GCC 7.2
    echo "Installing GCC 7.2"
    sudo yum install centos-release-scl-rh -y
    sudo yum --enablerepo=centos-sclo-rh-testing install devtoolset-7-gcc -y
    sudo yum --enablerepo=centos-sclo-rh-testing install devtoolset-7-gcc-c++ -y
    sudo yum --enablerepo=centos-sclo-rh-testing install devtoolset-7-gcc-gfortran -y  

}

get_gromacs()
{
    echo "Get Gromacs"
    wget -q http://ftp.gromacs.org/pub/gromacs/gromacs-${GMX_VERSION}.tar.gz
    tar xvf gromacs-${GMX_VERSION}.tar.gz
}

build_gromacs()
{
    source /opt/intel/impi/*/bin64/mpivars.sh

    echo "Build Gromacs"
    cd gromacs-${GMX_VERSION}
    sudo mkdir build
    cd build
    sudo cmake \
            -DBUILD_SHARED_LIBS=off \
            -DBUILD_TESTING=off \
            -DREGRESSIONTEST_DOWNLOAD=OFF \
            -DCMAKE_C_COMPILER=`which mpicc` \
            -DCMAKE_CXX_COMPILER=`which mpicxx` \
            -DGMX_BUILD_OWN_FFTW=on \
            -DGMX_DOUBLE=off \
            -DGMX_EXTERNAL_BLAS=off \
            -DGMX_EXTERNAL_LAPACK=off \
            -DGMX_FFT_LIBRARY=fftw3 \
            -DGMX_GPU=off \
            -DGMX_MPI=on \
            -DGMX_OPENMP=on \
            -DGMX_X11=off \
            -DCMAKE_EXE_LINKER_FLAGS="-zmuldefs " \
            -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
            ..

    sudo make -j 8
    sudo make install
}

setup_build_tools
get_gromacs

export PATH=/opt/rh/devtoolset-7/root/bin/:$PATH

build_gromacs