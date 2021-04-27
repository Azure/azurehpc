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
#     spack install opm-grid
#
# You can edit this file again by typing:
#
#     spack edit opm-grid
#
# See the Spack documentation for more information on packaging.
# ----------------------------------------------------------------------------

from spack import *


class OpmGrid(CMakePackage):
    """FIXME: Put a proper description of your package here."""

    homepage = "https://opm-project.org/"
    url      = "https://github.com/OPM/opm-grid/archive/refs/tags/release/2020.10/final.tar.gz"

    version('2020.10', sha256='9328def2e053c7d563866412287978d751f90cec04850801303e0950e27b1c38')
    version('2020.04', sha256='9cfe00233779128b9744c4763315800324d1ff1ffa056c6525789b3aec984ac7')

    depends_on('opm-common')

    def cmake_args(self):
        args = [
                '-DUSE_MPI=1',
                '-DUSE_OPENMP_DEFAULT=1'
        ]
        return args
