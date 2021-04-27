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
#     spack install ecl
#
# You can edit this file again by typing:
#
#     spack edit ecl
#
# See the Spack documentation for more information on packaging.
# ----------------------------------------------------------------------------

from spack import *


class Ecl(CMakePackage):
    """FIXME: Put a proper description of your package here."""

    url      = "https://github.com/equinor/ecl/archive/refs/tags/2.10.0.tar.gz"

    version('2.10.1', sha256='f4d9aa707f3c18ab48f863762ee602337cfeef84f74f0c6d9e57263afd26c846')
