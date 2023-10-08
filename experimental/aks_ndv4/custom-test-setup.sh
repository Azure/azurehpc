#!/bin/bash
set -e

NVCC=/usr/local/cuda/bin/nvcc
SRC_DIR=$1
EXE_DIR=$2

# location for any source files default current directory
if [[ -z "$SRC_DIR" ]];then
        SRC_DIR=.
fi

# location where we will be putting execuatble. Must match custom tests.
if [[ -z "$EXE_DIR" ]];then
        EXE_DIR=/opt/azurehpc/test/nhc
fi

mkdir -p $EXE_DIR

function install_perf_test(){
        type=$1
        # create perf-test executables
        if [[ "$type" == "cuda" ]]; then
                echo -e "Building PerfTest with CUDA"
        else
                echo -e "Building PerfTest"
        fi

        VERSION=4.5-0.12
        VERSION_HASH=ge93c538

        distro=`awk -F= '/^NAME/{print $2}' /etc/os-release`
        if [[ $distro =~ "Ubuntu" ]]; then
                apt-get install -y libpci-dev
        elif [[ $distro =~ "AlmaLinux" ]]; then
                dnf install -y pciutils-devel
        else
                echo "OS version is not supported, Perf-test build skipped. Proceed w/ caution."
                return 1
        fi

        pushd ${EXE_DIR}
        perftest_dir="perftest-${VERSION}"
        mkdir -p ${EXE_DIR}/${perftest_dir}
        archive_url="https://github.com/linux-rdma/perftest/releases/download/v${VERSION}/perftest-${VERSION}.${VERSION_HASH}.tar.gz"
        wget -q -O - $archive_url | tar -xz --strip=1 -C ${EXE_DIR}/${perftest_dir}

        pushd ${perftest_dir}
        if [[ "$type" == "cuda" ]]; then
                ./configure CUDA_H_PATH=/usr/local/cuda/include/cuda.h
        else
                ./autogen.sh
                ./configure
        fi

        make
        popd
        popd
}


#Nvidia installs
if lspci | grep -iq NVIDIA ; then
        # CUDA BW Test Setup
        #Test if nvcc is installed and if so install gpu-copy test.
        if test -f "$NVCC"; then
                #Compile the gpu-copy benchmark.

                cufile="$SRC_DIR/gpu-copy.cu"
                outfile="$EXE_DIR/gpu-copy"

                #Test if the default gcc compiler is new enough to compile gpu-copy.
                #If it is not then use the 9.2 compiler, that should be installed in
                #/opt.
                if [ $(gcc -dumpversion | cut -d. -f1) -gt 6 ]; then
                        $NVCC -lnuma $cufile -o $outfile
                else
                        $NVCC --compiler-bindir /opt/gcc-9.2.0/bin \
                                -lnuma $cufile -o $outfile
                fi
        else
                echo "$NVCC not found. Exiting setup"
        fi

#       install_perf_test "cuda"

else

        install_perf_test

        # Stream
        if command -v /opt/AMD/aocc-compiler-4.0.0/bin/clang &> /dev/null || command -v clang &> /dev/null; then
                echo -e "clang compiler found Building Stream"
                pushd ${SRC_DIR}/stream
                if ! [[ -f "stream.c" ]]; then
                        wget https://www.cs.virginia.edu/stream/FTP/Code/stream.c
                fi


                HB_HX_SKUS="standard_hb176rs_v4|standard_hb176-144rs_v4|standard_hb176-96rs_v4|standard_hb176-48rs_v4|standard_hb176-24rs_v4|standard_hx176rs|standard_hx176-144rs|standard_hx176-96rs|standard_hx176-48rs|standard_hx176-24rs"
                SKU=$( curl -H Metadata:true --max-time 10 -s "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2021-01-01&format=text")
                SKU=$(echo "$SKU" | tr '[:upper:]' '[:lower:]')

                if [[ "$HB_HX_SKUS" =~ "$SKU"  ]]; then
                        BUILD=ZEN4
                elif echo $SKU | grep "hb120rs_v3"; then
                        BUILD=ZEN3
                elif echo $SKU | grep "hb120rs_v2"; then
                        BUILD=ZEN2
                else
                        #default to zen3 build
                        BUILD=ZEN3
                fi

                if command -v /opt/AMD/aocc-compiler-4.0.0/bin/clang &> /dev/null; then
                        make $BUILD CC=/opt/AMD/aocc-compiler-4.0.0/bin/clang EXEC_DIR=$EXE_DIR
                else
                        make $BUILD CC=clang EXEC_DIR=$EXE_DIR
                fi
                popd
        else
                echo "clang command not found. Skipping Stream build. Add clang to PATH ENV variable and rerun script to build Stream"
        fi

fi

# Ensure lstopo-no-graphics is installed for the azure_hw_topology_check.nhc
distro=`awk -F= '/^NAME/{print $2}' /etc/os-release`
if [[ $distro =~ "Ubuntu" ]]; then
        apt-get install -y hwloc
elif [[ $distro =~ "AlmaLinux" ]]; then
        dnf install -y hwloc
else
        echo "OS version is not supported, azure_hw_topology_check will not work."
        return 1
fi

# copy all custom test to the nhc scripts dir
cp $SRC_DIR/*.nhc /etc/nhc/scripts
