     Show Dotfiles Show Owner/Mode
/anfhome/hpcuser/azhop-spack/packages/opm-models/
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
#     spack install opm-models
#
# You can edit this file again by typing:
#
#     spack edit opm-models
#
# See the Spack documentation for more information on packaging.
# ----------------------------------------------------------------------------

from spack import *


class OpmModels(CMakePackage):
    """FIXME: Put a proper description of your package here."""

    homepage = "https://opm-project.org/"
    url      = "https://github.com/OPM/opm-models/archive/refs/tags/release/2020.10/final.tar.gz"

    version('2020.10', sha256='5bf4fe3e64e428a16eb9343fd7dda07f4dcdc0b1caa510881994948aac342948')
    version('2020.04', sha256='5ef07f39693bda162948b8c205604a65af23be44ff5a40f74766e7315238e7b8')

    depends_on('opm-grid')
    depends_on('opm-material')

    def cmake_args(self):
        args = [
                '-DUSE_MPI=1',
                '-DUSE_OPENMP_DEFAULT=1'
        ]
        return args
