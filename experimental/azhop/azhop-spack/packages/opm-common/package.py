# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

# ----------------------------------------------------------------------------
#
#     spack install opm-common
#
# You can edit this file again by typing:
#
#     spack edit opm-common
#
# See the Spack documentation for more information on packaging.
# ----------------------------------------------------------------------------

from spack import *


class OpmCommon(CMakePackage):
    """FIXME: Put a proper description of your package here."""

    homepage = "https://opm-project.org/"
    url      = "https://github.com/OPM/opm-common/archive/refs/tags/release/2020.10/final.tar.gz"

    version('2020.10', sha256='fd9c2377bb18e4afb65f13192839cf79af2bf057e07c1b36fae7c9482d4715e3')
    version('2020.04', sha256='6687ab308143c86886d13bb3d713df6116d7e43e245b745c903936ad768b176b')

    depends_on('blas')
    depends_on('boost')
    depends_on('dune')
    depends_on('mpi')
    depends_on('parmetis')
    depends_on('zoltan')

    def cmake_args(self):
        args = [
        '-DUSE_MPI=1',
        '-DUSE_OPENMP_DEFAULT=1'
    ]
        return args