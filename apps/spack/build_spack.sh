#!/bin/bash

APP_NAME=spack
APP_VERSION=0.13.1
SHARED_APPS=/apps
STORAGE_ENDPOINT=https://cgspack.blob.core.windows.net
USER=`whoami`
SCRIPT1=config.yaml

sku_type=$1
email_address=$2
STORAGE_ENDPOINT=$3

cat > ~/${SCRIPT1} << EOF
# -------------------------------------------------------------------------
config:
  # This is the path to the root of the Spack install tree.
  install_tree: /apps/spack/$sku_type


  # Locations where templates should be found
  template_dirs:
    - \$spack/share/spack/templates


  # Default directory layout
  install_path_scheme: "\${ARCHITECTURE}/\${COMPILERNAME}-\${COMPILERVER}/\${PACKAGE}-\${VERSION}-\${HASH}"


  # Locations where different types of modules should be installed.
  module_roots:
    tcl:    /apps/modulefiles/spack/tcl/$sku_type
    lmod:   /apps/modules/spack/lmod/$sku_type


  # Temporary locations Spack can try to use for builds.
  #
  # Spack will use the first one it finds that exists and is writable.
  # You can use \$tempdir to refer to the system default temp directory
  # (as returned by tempfile.gettempdir()).
  #
  # A value of \$spack/var/spack/stage indicates that Spack should run
  # builds directly inside its install directory without staging them in
  # temporary space.
  #
  # The build stage can be purged with \`spack clean --stage\`.
  build_stage:
    - \$tempdir/spack-stage
    - ~/.spack/stage
#    - \$spack/var/spack/stage


  # Cache directory for already downloaded source tarballs and archived
  # repositories. This can be purged with \`spack clean --downloads\`.
  source_cache: /apps/spack/cache


  # Cache directory for miscellaneous files, like the package index.
  # This can be purged with \`spack clean --misc-cache\`
  misc_cache: ~/.spack/cache


  # If this is false, tools like curl that use SSL will not verify
  # certifiates. (e.g., curl will use use the -k option)
  verify_ssl: true


  # If set to true, Spack will attempt to build any compiler on the spec
  # that is not already available. If set to False, Spack will only use
  # compilers already configured in compilers.yaml
  install_missing_compilers: False


  # If set to true, Spack will always check checksums after downloading
  # archives. If false, Spack skips the checksum step.
  checksum: true


  # If set to true, \`spack install\` and friends will NOT clean
  # potentially harmful variables from the build environment. Use wisely.
  dirty: false


  # The language the build environment will use. This will produce English
  # compiler messages by default, so the log parser can highlight errors.
  # If set to C, it will use English (see man locale).
  # If set to the empty string (''), it will use the language from the
  # user's environment.
  build_language: C


  # When set to true, concurrent instances of Spack will use locks to
  # avoid modifying the install tree, database file, etc. If false, Spack
  # will disable all locking, but you must NOT run concurrent instances
  # of Spack.  For filesystems that don't support locking, you should set
  # this to false and run one Spack at a time, but otherwise we recommend
  # enabling locks.
  locks: true


  # The default number of jobs to use when running \`make\` in parallel.
  # If set to 4, for example, \`spack install\` will run \`make -j4\`.
  # If not set, Spack will use all available cores up to 16.
  # build_jobs: 16


  # If set to true, Spack will use ccache to cache C compiles.
  ccache: false

  # How long to wait to lock the Spack installation database. This lock is used
  # when Spack needs to manage its own package metadata and all operations are
  # expected to complete within the default time limit. The timeout should
  # therefore generally be left untouched.
  db_lock_timeout: 120


  # How long to wait when attempting to modify a package (e.g. to install it).
  # This value should typically be 'null' (never time out) unless the Spack
  # instance only ever has a single user at a time, and only if the user
  # anticipates that a significant delay indicates that the lock attempt will
  # never succeed.
  package_lock_timeout: null


  # Control whether Spack embeds RPATH or RUNPATH attributes in ELF binaries.
  # Has no effect on macOS. DO NOT MIX these within the same install tree.
  # See the Spack documentation for details.
  shared_linking: 'rpath'
EOF

SCRIPT2=modules.yaml
cat > ~/${SCRIPT2} << EOF
# -------------------------------------------------------------------------
modules:
  enable:
    - tcl
    - lmod
  prefix_inspections:
    bin:
      - PATH
    libexec/osu-micro-benchmarks/mpi/collective:
      - PATH
    libexec/osu-micro-benchmarks/mpi/one-sided:
      - PATH
    libexec/osu-micro-benchmarks/mpi/pt2pt:
      - PATH
    libexec/osu-micro-benchmarks/mpi/startup:
      - PATH
    man:
      - MANPATH
    share/man:
      - MANPATH
    share/aclocal:
      - ACLOCAL_PATH
    lib:
      - LIBRARY_PATH
      - LD_LIBRARY_PATH
    lib64:
      - LIBRARY_PATH
      - LD_LIBRARY_PATH
    include:
      - CPATH
    lib/pkgconfig:
      - PKG_CONFIG_PATH
    lib64/pkgconfig:
      - PKG_CONFIG_PATH
    '':
      - CMAKE_PREFIX_PATH

  lmod:
    hierarchy:
      - mpi
EOF

SCRIPT3=packages.yaml
cat > ~/${SCRIPT3} << EOF
# -------------------------------------------------------------------------
packages:
  openmpi:
    modules:
       openmpi@4.0.2%gcc@9.2.0: mpi/openmpi-4.0.2
    buildable: False
  mvapich2:
    modules:
       mvapich2@2.3.2%gcc@9.2.0: mpi/mvapich2-2.3.2
    buildable: False
  hpcx:
    modules:
       hpcx@2.5.0%gcc@9.2.0: mpi/hpcx-v2.5.0
    buildable: False
  intel-mpi:
    paths:
       intel-mpi@2019.5.281: /opt/intel/compilers_and_libraries_2019.5.281/linux/mpi
    buildable: False
  gcc:
    modules:
       gcc@9.2.0: gcc-9.2.0
    buildable: False
  all:
    compiler: [gcc, intel, pgi, clang, xl, nag, fj]
    providers:
      D: [ldc]
      awk: [gawk]
      blas: [openblas]
      daal: [intel-daal]
      elf: [elfutils]
      fftw-api: [fftw]
      gl: [mesa+opengl, opengl]
      glx: [mesa+glx, opengl]
      glu: [mesa-glu, openglu]
      golang: [gcc]
      ipp: [intel-ipp]
      java: [openjdk, jdk, ibm-java]
      jpeg: [libjpeg-turbo, libjpeg]
      lapack: [openblas]
      mariadb-client: [mariadb-c-client, mariadb]
      mkl: [intel-mkl]
      mpe: [mpe2]
      mpi: [openmpi, mpich, mvapich2, hpcx]
      mysql-client: [mysql, mariadb-c-client]
      opencl: [pocl]
      pil: [py-pillow]
      pkgconfig: [pkgconf, pkg-config]
      scalapack: [netlib-scalapack]
      szip: [libszip, libaec]
      tbb: [intel-tbb]
      unwind: [libunwind]
    permissions:
      read: world
      write: user
EOF

SCRIPT4=compilers.yaml
cat > ~/${SCRIPT4} << EOF
compilers:
- compiler:
    environment: {}
    extra_rpaths: []
    flags: {}
    modules: []
    operating_system: centos7
    paths:
      cc: /usr/bin/gcc
      cxx: /usr/bin/g++
      f77: /usr/bin/gfortran
      fc: /usr/bin/gfortran
    spec: gcc@4.8.5
    target: x86_64
- compiler:
    environment: {}
    extra_rpaths: []
    flags: {}
    modules: [gcc-9.2.0]
    operating_system: centos7
    paths:
      cc: /opt/gcc-9.2.0/bin/gcc
      cxx: /opt/gcc-9.2.0/bin/g++
      f77: /opt/gcc-9.2.0/bin/gfortran
      fc: /opt/gcc-9.2.0/bin/gfortran
    spec: gcc@9.2.0
    target: x86_64
EOF

HPCX_PACKAGE=package.py
cat > ~/${HPCX_PACKAGE} << EOF
# Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)


import os
import sys
import llnl.util.tty as tty


class Hpcx(AutotoolsPackage):
    """An open source Message Passing Interface implementation.

    The Open MPI Project is an open source Message Passing Interface
    implementation that is developed and maintained by a consortium
    of academic, research, and industry partners. Open MPI is
    therefore able to combine the expertise, technologies, and
    resources from all across the High Performance Computing
    community in order to build the best MPI library available.
    Open MPI offers advantages for system and software vendors,
    application developers and computer science researchers.
    """

    homepage = "http://www.open-mpi.org"
    url = "https://www.open-mpi.org/software/ompi/v4.0/downloads/openmpi-4.0.0.tar.bz2"
    list_url = "http://www.open-mpi.org/software/ompi/"
    git = "https://github.com/open-mpi/ompi.git"

    version('develop', branch='master')

    provides('mpi')


    def setup_dependent_environment(self, spack_env, run_env, dependent_spec):
        self.prefix.bin = "/opt/hpcx-v2.5.0-gcc-MLNX_OFED_LINUX-4.7-1.0.0.1-redhat7.7-x86_64/ompi/bin"
        spack_env.set('MPICC',  join_path(self.prefix.bin, 'mpicc'))
        spack_env.set('MPICXX', join_path(self.prefix.bin, 'mpic++'))
        spack_env.set('MPIF77', join_path(self.prefix.bin, 'mpif77'))
        spack_env.set('MPIF90', join_path(self.prefix.bin, 'mpif90'))

        spack_env.set('OMPI_CC', spack_cc)
        spack_env.set('OMPI_CXX', spack_cxx)
        spack_env.set('OMPI_FC', spack_fc)
        spack_env.set('OMPI_F77', spack_f77)

    def setup_dependent_package(self, module, dependent_spec):
        self.prefix.bin = "/opt/hpcx-v2.5.0-gcc-MLNX_OFED_LINUX-4.7-1.0.0.1-redhat7.7-x86_64/ompi/bin"
        self.spec.mpicc = join_path(self.prefix.bin, 'mpicc')
        self.spec.mpicxx = join_path(self.prefix.bin, 'mpic++')
        self.spec.mpifc = join_path(self.prefix.bin, 'mpif90')
        self.spec.mpif77 = join_path(self.prefix.bin, 'mpif77')
        self.spec.mpicxx_shared_libs = [
            join_path(self.prefix.lib, 'libmpi_cxx.{0}'.format(dso_suffix)),
            join_path(self.prefix.lib, 'libmpi.{0}'.format(dso_suffix))
        ]
EOF

sudo yum install -y python3

SPACKDIR=${SHARED_APPS}/${APP_NAME}/${APP_VERSION}
mkdir -p $SPACKDIR
cd $SPACKDIR
git clone https://github.com/spack/spack.git
cd spack
git checkout tags/v${APP_VERSION}
mkdir ${SPACKDIR}/spack/var/spack/repos/builtin/packages/hpcx
cp $HPCX_PACKAGE  ${SPACKDIR}/spack/var/spack/repos/builtin/packages/hpcx
source ${SPACKDIR}/spack/share/spack/setup-env.sh
echo "source ${SPACKDIR}/spack/share/spack/setup-env.sh" >> ~/.bash_profile
sudo mkdir /mnt/resource/spack
sudo chown $USER /mnt/resource/spack
mkdir ~/.spack
mv ~/${SCRIPT1} ~/.spack
mv ~/${SCRIPT2} ~/.spack
mv ~/${SCRIPT3} ~/.spack
mv ~/${SCRIPT4} ~/.spack
mkdir -p /apps/spack/${sku_type}
spack gpg init
spack gpg create ${sku_type}_gpg $email_address
spack mirror add ${sku_type}_buildcache ${STORAGE_ENDPOINT}/buildcache/${sku_type}
