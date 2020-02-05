#!/bin/bash

TAR_SAS_URL="https://azhpcscus.blob.core.windows.net/apps/OpenFOAM-6/openfoam-6_ipmi2018_gcc82.tgz"
SHARED_APP=/apps
MODULE_DIR=${SHARED_APP}/modulefiles
APP_NAME=OpenFOAM
APP_VERSION=6
MODULE_NAME=${APP_NAME}_${APP_VERSION}

function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${MODULE_NAME}
#%Module
setenv CLASSPATH {/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/lib/mpi.jar};
setenv FOAM_APP {${SHARED_APP}/OpenFOAM/OpenFOAM-6/applications};
setenv FOAM_APPBIN {${SHARED_APP}/OpenFOAM/OpenFOAM-6/platforms/linux64GccDPInt32Opt/bin};
setenv FOAM_ETC {${SHARED_APP}/OpenFOAM/OpenFOAM-6/etc};
setenv FOAM_EXT_LIBBIN {${SHARED_APP}/OpenFOAM/ThirdParty-6/platforms/linux64GccDPInt32/lib};
setenv FOAM_INST_DIR {${SHARED_APP}/OpenFOAM};
setenv FOAM_JOB_DIR {${SHARED_APP}/OpenFOAM/jobControl};
setenv FOAM_LIBBIN {${SHARED_APP}/OpenFOAM/OpenFOAM-6/platforms/linux64GccDPInt32Opt/lib};
setenv FOAM_MPI {mpi};
setenv FOAM_RUN {/share/home/hpcuser/OpenFOAM/hpcuser-6/run};
setenv FOAM_SETTINGS {};
setenv FOAM_SIGFPE {};
setenv FOAM_SITE_APPBIN {${SHARED_APP}/OpenFOAM/site/6/platforms/linux64GccDPInt32Opt/bin};
setenv FOAM_SITE_LIBBIN {${SHARED_APP}/OpenFOAM/site/6/platforms/linux64GccDPInt32Opt/lib};
setenv FOAM_SOLVERS {${SHARED_APP}/OpenFOAM/OpenFOAM-6/applications/solvers};
setenv FOAM_SRC {${SHARED_APP}/OpenFOAM/OpenFOAM-6/src};
setenv FOAM_TUTORIALS {${SHARED_APP}/OpenFOAM/OpenFOAM-6/tutorials};
setenv FOAM_USER_APPBIN {/share/home/hpcuser/OpenFOAM/hpcuser-6/platforms/linux64GccDPInt32Opt/bin};
setenv FOAM_USER_LIBBIN {/share/home/hpcuser/OpenFOAM/hpcuser-6/platforms/linux64GccDPInt32Opt/lib};
setenv FOAM_UTILITIES {${SHARED_APP}/OpenFOAM/OpenFOAM-6/applications/utilities};
setenv I_MPI_ROOT {/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi};
setenv LD_LIBRARY_PATH {/opt/gcc-9.2.0/lib64:${SHARED_APP}/OpenFOAM/ThirdParty-6/platforms/linux64Gcc/gperftools-svn/lib:${SHARED_APP}/OpenFOAM/OpenFOAM-6/platforms/linux64GccDPInt32Opt/lib/mpi:${SHARED_APP}/OpenFOAM/ThirdParty-6/platforms/linux64GccDPInt32/lib/mpi:/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/lib64:/share/home/hpcuser/OpenFOAM/hpcuser-6/platforms/linux64GccDPInt32Opt/lib:${SHARED_APP}/OpenFOAM/site/6/platforms/linux64GccDPInt32Opt/lib:${SHARED_APP}/OpenFOAM/OpenFOAM-6/platforms/linux64GccDPInt32Opt/lib:${SHARED_APP}/OpenFOAM/ThirdParty-6/platforms/linux64GccDPInt32/lib:${SHARED_APP}/OpenFOAM/OpenFOAM-6/platforms/linux64GccDPInt32Opt/lib/dummy:/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/lib:/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/mic/lib};
setenv MANPATH {/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/man:/opt/pbs/share/man:};
setenv MPI_ARCH_PATH {/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi};
setenv MPI_BUFFER_SIZE {20000000};
setenv MPI_ROOT {/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi};
prepend-path PATH {${SHARED_APP}/OpenFOAM/site/6/platforms/linux64GccDPInt32Opt/bin};
prepend-path PATH {${SHARED_APP}/OpenFOAM/OpenFOAM-6/platforms/linux64GccDPInt32Opt/bin};
prepend-path PATH {/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/bin64};
prepend-path PATH {${SHARED_APP}/OpenFOAM/ThirdParty-6/platforms/linux64Gcc/gperftools-svn/bin};
append-path PATH {/usr/sbin};
append-path PATH {/opt/ibutils/bin};
append-path PATH {/opt/pbs/bin};
append-path PATH {/share/home/hpcuser/.local/bin};
append-path PATH {/share/home/hpcuser/bin};
setenv ParaView_DIR {${SHARED_APP}/OpenFOAM/ThirdParty-6/platforms/linux64Gcc/ParaView-5.4.0};
setenv ParaView_GL {mesa};
setenv ParaView_MAJOR {5.4};
setenv ParaView_VERSION {5.4.0};
setenv WM_ARCH {linux64};
setenv WM_ARCH_OPTION {64};
setenv WM_CC {gcc};
setenv WM_CFLAGS {-m64 -fPIC};
setenv WM_COMPILER {Gcc};
setenv WM_COMPILER_LIB_ARCH {64};
setenv WM_COMPILER_TYPE {system};
setenv WM_COMPILE_OPTION {Opt};
setenv WM_CXX {g++};
setenv WM_CXXFLAGS {-m64 -fPIC -std=c++0x};
setenv WM_DIR {${SHARED_APP}/OpenFOAM/OpenFOAM-6/wmake};
setenv WM_LABEL_OPTION {Int32};
setenv WM_LABEL_SIZE {32};
setenv WM_LDFLAGS {-m64};
setenv WM_LINK_LANGUAGE {c++};
setenv WM_MPLIB {INTELMPI};
setenv WM_OPTIONS {linux64GccDPInt32Opt};
setenv WM_OSTYPE {POSIX};
setenv WM_PRECISION_OPTION {DP};
setenv WM_PROJECT {OpenFOAM};
setenv WM_PROJECT_DIR {${SHARED_APP}/OpenFOAM/OpenFOAM-6};
setenv WM_PROJECT_INST_DIR {${SHARED_APP}/OpenFOAM};
setenv WM_PROJECT_USER_DIR {/share/home/hpcuser/OpenFOAM/hpcuser-6};
setenv WM_PROJECT_VERSION {6};
setenv WM_THIRD_PARTY_DIR {${SHARED_APP}/OpenFOAM/ThirdParty-6};
EOF
}

mkdir -p ${SHARED_APP}/${APP_NAME}
pushd ${SHARED_APP}/${APP_NAME}
if [ ! -f ${SHARED_APP}/${APP_NAME}/${INSTALL_TAR} ]; then
wget -nv "$TAR_SAS_URL" -O - | tar zx
fi
popd

create_modulefile
