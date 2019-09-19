#!/bin/bash

APP_NAME=spack
APP_VERSION=0.12.1
SHARED_APPS=/apps
USER=`whoami`
SCRIPT1=config.yaml

sku_type=$1
email_address=$2


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
    tcl:    \$spack/share/spack/modules
    lmod:   /apps/modules/spack/lmod/$sku_type
    dotkit: \$spack/share/spack/dotkit


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
    - \$tempdir
    - /nfs/tmp2/\$USER
    - \$spack/var/spack/stage


  # Cache directory for already downloaded source tarballs and archived
  # repositories. This can be purged with \`spack clean --downloads\`.
  source_cache: /apps/spack/cache


  # Cache directory for miscellaneous files, like the package index.
  # This can be purged with \`spack clean --misc-cache\`
  misc_cache: ~/.spack/cache


  # If this is false, tools like curl that use SSL will not verify
  # certifiates. (e.g., curl will use use the -k option)
  verify_ssl: true


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
  # If not set, all available cores are used by default.
  build_jobs: 16


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
EOF

SCRIPT2=modules.yaml
cat > ~/${SCRIPT2} << EOF
# -------------------------------------------------------------------------
modules:
  enable:
    - lmod
    - tcl
    - dotkit
  prefix_inspections:
    bin:
      - PATH
    man:
      - MANPATH
    share/man:
      - MANPATH
    share/aclocal:
      - ACLOCAL_PATH
    lib:
      - LIBRARY_PATH
    lib64:
      - LIBRARY_PATH
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
       openmpi@4.0.1%gcc@8.2.0: mpi/openmpi-4.0.1
    buildable: False
  mpich:
    modules:
       mpich@3.3%gcc@8.2.0: mpi/mpich-3.3
    buildable: False
  mvapich2:
    modules:
       mvapich2@2.3.1%gcc@8.2.0: mpi/mvapich2-2.3.1
    buildable: False
  hpcx:
    modules:
       hpcx@2.4.1%gcc@8.2.0: mpi/hpcx-v2.4.1
    buildable: False
  gcc:
    modules:
       gcc@8.2.0: gcc-8.2.0
    buildable: False
  all:
    compiler: [gcc, intel, pgi, clang, xl, nag]
    providers:
      D: [ldc]
      awk: [gawk]
      blas: [openblas]
      daal: [intel-daal]
      elf: [elfutils]
      fftw-api: [fftw]
      gl: [mesa, opengl]
      glu: [mesa-glu, openglu]
      golang: [gcc]
      ipp: [intel-ipp]
      java: [jdk]
      jpeg: [libjpeg-turbo, libjpeg]
      lapack: [openblas]
      mkl: [intel-mkl]
      mpe: [mpe2]
      mpi: [openmpi, mpich, mvapich2, hpcx]
      opencl: [pocl]
      openfoam: [openfoam-com, openfoam-org, foam-extend]
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
    modules: [gcc-8.2.0]
    operating_system: centos7
    paths:
      cc: /opt/gcc-8.2.0/bin/gcc
      cxx: /opt/gcc-8.2.0/bin/g++
      f77: /opt/gcc-8.2.0/bin/gfortran
      fc: /opt/gcc-8.2.0/bin/gfortran
    spec: gcc@8.2.0
    target: x86_64
EOF

SPACKDIR=${SHARED_APPS}/${APP_NAME}/${APP_VERSION}
mkdir -p $SPACKDIR
cd $SPACKDIR
git clone https://github.com/spack/spack.git
cd spack
git checkout tags/$SPACKVERSION
source ${SPACKDIR}/spack/share/spack/setup-env.sh
echo "source ${SPACKDIR}/spack/share/spack/setup-env.sh" >> ~/.bash_profile
sudo mkdir /mnt/resource/spack
sudo chown $USER /mnt/resource/spack
mkdir ~/.spack
cp ~/${SCRIPT1} ~/.spack
cp ~/${SCRIPT2} ~/.spack
cp ~/${SCRIPT3} ~/.spack
cp ~/${SCRIPT4} ~/.spack
mkdir -p /apps/spack/${sku_type}
spack gpg init
spack gpg create ${sku_type}_gpg $email_address
spack mirror add ${sku_type}_buildcache file:///apps/spack/${sku_type}
