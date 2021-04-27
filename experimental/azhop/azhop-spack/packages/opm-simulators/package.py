     Show Dotfiles Show Owner/Mode
/anfhome/hpcuser/azhop-spack/packages/opm-simulators/
# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

# ----------------------------------------------------------------------------
# If you submit this package back to Spack as a pull request,
# please first remove this boilerplate and all FIXME comments.
#
# This is a template package file for Spack.  We've put "FIXME"
# next to all the things you'll want to change. Once you've handled
# them, you can save this file and test your package like this:
#
#     spack install opm-simulators
#
# You can edit this file again by typing:
#
#     spack edit opm-simulators
#
# See the Spack documentation for more information on packaging.
# ----------------------------------------------------------------------------

from spack import *


class OpmSimulators(CMakePackage):
    """FIXME: Put a proper description of your package here."""

    homepage = "https://opm-project.org/"
    url      = "https://github.com/OPM/opm-simulators/archive/refs/tags/release/2020.10/final.tar.gz"

    version('2020.10', sha256='c2d25c600c6187c1cfe0f49729316121b137ef18596d036eb8d68e54b38e2efb')
    version('2020.04', sha256='29de3e7b0d22a60a33f339b5e3bfde81e767bac224a17f6da91b49e6ead240d4')

    depends_on('opm-common')
    depends_on('opm-grid')
    depends_on('opm-material')
    depends_on('opm-models')

    depends_on('parmetis')
    depends_on('mpi')
    depends_on('zoltan')
    depends_on('boost')
    depends_on('dune')
    depends_on('blas')
    depends_on('lapack')

    def cmake_args(self):
        args = [
                '-DUSE_MPI=1',
                '-DUSE_OPENMP_DEFAULT=1'
        ]
        return args
