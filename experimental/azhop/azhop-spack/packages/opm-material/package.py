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
#     spack install opm-material
#
# You can edit this file again by typing:
#
#     spack edit opm-material
#
# See the Spack documentation for more information on packaging.
# ----------------------------------------------------------------------------

from spack import *


class OpmMaterial(CMakePackage):
    """FIXME: Put a proper description of your package here."""

    homepage = "https://opm-project.org/"
    url      = "https://github.com/OPM/opm-material/archive/refs/tags/release/2020.10/final.tar.gz"

    version('2020.10', sha256='31aacab75060329be5c014078e4c3d49c0bd90e9a32c4e0ff073df44c039ca24')
    version('2020.04', sha256='e88b749cbec88a693ad8259b718ebe4e61f31bc8e5fbb0950364fbb2be8ec74f')

    depends_on('opm-common')

    def cmake_args(self):
        args = [
                '-DUSE_MPI=1',
                '-DUSE_OPENMP_DEFAULT=1'
        ]
        return args
