##
# Copyright 2015-2021 Ghent University
#
# This file is part of EasyBuild,
# originally created by the HPC team of Ghent University (http://ugent.be/hpc/en),
# with support of Ghent University (http://ugent.be/hpc),
# the Flemish Supercomputer Centre (VSC) (https://www.vscentrum.be),
# Flemish Research Foundation (FWO) (http://www.fwo.be/en)
# and the Department of Economy, Science and Innovation (EWI) (http://www.ewi-vlaanderen.be/en).
#
# http://github.com/hpcugent/easybuild
#
# EasyBuild is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation v2.
#
# EasyBuild is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with EasyBuild.  If not, see <http://www.gnu.org/licenses/>.
##
"""
EasyBuild support for using MPI libraries already available in VM deployed with marketplace HPC images.

@author Davide Vanzo (Microsoft Azure)
"""
import os
import re
from collections import defaultdict

from easybuild.framework.easyblock import EasyBlock
from easybuild.framework.easyconfig import CUSTOM
from easybuild.tools.build_log import EasyBuildError
from easybuild.tools.filetools import search_file, read_file
from easybuild.tools.run import run_cmd


class AzureMPI(EasyBlock):
    """
    Allows replacing EasyBuild-built MPI library with the selected MPI library
    already installed in the VM. Only generates the module file pointing to the
    specific installation path and containing all required environment variables.
    Selection is done through the easyconfig name parameter:
        * OpenMPI (HPC-X)
    """

    @staticmethod
    def extra_options(extra_vars=None):
        """Add custom easyconfig parameters for AzureMPI easyblock."""

        extra_vars = EasyBlock.extra_options(extra=extra_vars)

        # Add easyconfig parameter to specify root path of the exising MPI installation
        extra_vars.update({
            'mpi_install_path': ['/opt', "Specify root installation path for existing MPI library "
                                         "(default: /opt)", CUSTOM],
        })

        return extra_vars

    def extract_ompi_setting(self, pattern, txt):
        """Extract a particular OpenMPI setting from provided string (e.g. ompi_info output)."""

        version_regex = re.compile(r'^\s+%s: (.*)$' % pattern, re.M)
        res = version_regex.search(txt)
        if res:
            setting = res.group(1)
            self.log.debug("Extracted OpenMPI setting %s: '%s' from search text", pattern, setting)
        else:
            raise EasyBuildError("Failed to extract OpenMPI setting '%s' using regex pattern '%s' from: %s",
                                 pattern, version_regex.pattern, txt)

        return setting

    def prepare_step(self, *args, **kwargs):
        """Determine MPI prefix path, MPI version and any required envvars."""

        # Keep track of original values of vars that are subject to change
        self.orig_installdir = self.installdir
        self.orig_version = self.cfg['version']

        # Use easyconfig name parameter to determine target MPI type
        self.mpi_name = self.cfg['name'].lower()

        # Ensure that MPI exists within the root path specified in mpi_install_path
        # and extract MPI-specific information
        if self.mpi_name == 'openmpi':
            # For HPC-X OpenMPI, ensure one and only one HPC-X init script exists and save its path
            hpcx_init_filename = 'hpcx-init.sh'
            _, hits = search_file([self.cfg['mpi_install_path']], hpcx_init_filename)

            if not hits:
                raise EasyBuildError("No %s script recursively found in %s", hpcx_init_filename, self.cfg['mpi_install_path'])
            if len(hits) > 1:
                raise EasyBuildError("Multiple %s scripts recursively found in %s", hpcx_init_filename, self.cfg['mpi_install_path'])
            else:
                self.hpcx_init = hits[0]
                self.log.info("Found HPC-X init script: %s" % self.hpcx_init)

            # Get the HPC-X prefix from init script absolute path
            self.hpcx_dir = os.path.dirname(self.hpcx_init)

            # Find OpenMPI version from ompi_info output
            ompi_info_out, ec = run_cmd('source %s && hpcx_load && ompi_info' % self.hpcx_init, simple=False)
            if ec:
                raise EasyBuildError("Failed to initialize HPC-X and run ompi_info: %s", ompi_info_out)
            else:
                self.mpi_version = self.extract_ompi_setting('Open MPI', ompi_info_out)
                self.log.info("Found OpenMPI version: %s", self.mpi_version)

        else:
            raise EasyBuildError("Unrecognized MPI type: %s", self.mpi_name)

    def configure_step(self):
        """Nothing to be configured here."""
        pass

    def build_step(self):
        """Nothing to be built either."""
        pass

    def install_step(self):
        """Nothing to be installed."""
        pass

    def sanity_check_step(self, *args, **kwargs):
        """
        Nothing is being installed, so just being able to load the (fake) module is sufficient.
        """
        if self.cfg['exts_list'] or self.cfg['sanity_check_paths'] or self.cfg['sanity_check_commands']:
            super(AzureMPI, self).sanity_check_step(*args, **kwargs)
        else:
            self.log.info("Testing loading of module '%s' by means of sanity check" % self.full_mod_name)
            fake_mod_data = self.load_fake_module(purge=True)
            self.log.debug("Cleaning up after testing loading of module")
            self.clean_up_fake_module(fake_mod_data)

    def make_module_step(self, fake=False):
        """
        Custom module creation step for AzureMPI.
        In the generated module, set EBROOT* and EBVERSION* environment variables to the system
        installation path and actual MPI version.
        """

        # Use the system MPI installation path in the EBROOT* environment variable
        if self.mpi_name == 'openmpi':
            self.installdir = self.hpcx_dir

        # Use the actual MPI version in the EBVERSION* environment variable
        # This is critical for depending software that checks MPI version
        self.cfg['version'] = self.mpi_version

        res = super(AzureMPI, self).make_module_step(fake=fake)

        # Restore installation path and version to their original values
        self.installdir = self.orig_installdir
        self.cfg['version'] = self.orig_version

        return res

    def make_module_extra(self, *args, **kwargs):
        """
        Custom AzureMPI step for extracting system MPI required environment variables and paths
        to be set or appended in the generated module.
        """

        # Generate standard EB* environment variables
        extravars = super(AzureMPI, self).make_module_extra(*args, **kwargs)

        if self.mpi_name == 'openmpi':
            # Read hpcx_init script
            hpcx_init_content = read_file(self.hpcx_init)

            # Remove hpcx_unload function
            hpcx_init_content = re.search(r'(.*?)function hpcx_unload', hpcx_init_content, re.DOTALL).groups()[0]

            # Save all environment variables defined in hpcx_init and their values in dict
            init_vars = defaultdict(list)
            for envvar in re.findall(r'export (.*)', hpcx_init_content):
                var_name = envvar.split('=')[0]
                var_value = envvar.split('=')[1]

                # Remove variables starting with OLD used in the script only for hpcx_unload
                if var_name.startswith('OLD'):
                    continue

                # Ignore paths containing undefined HPCX_HMC_DIR
                if 'HPCX_HMC_DIR' in var_value:
                    continue

                # Remove trailing variable references in export calls (e.g. ":$PATH", ":$LD_LIBRARY_PATH")
                var_value = var_value.split(':$')[0]

                # Expand variables based on value of previously defined variables
                # e.g. HPCX_UCX_DIR=$HPCX_DIR/ucx -> HPCX_UCX_DIR=$mydir/ucx 
                for (var, values) in init_vars.items():
                    # Iterate over all values
                    for path in values:
                        var_value = var_value.replace('$%s' % var, path)

                # Remove "$mydir" and "$mydir/"
                var_value = re.sub(r'\$mydir', '', var_value)
                var_value = re.sub(r'^/', '', var_value)

                init_vars[var_name].append(var_value)

            # Add environment variables present in original HPC-X module but missing
            # in hpcx_init.sh script
            init_vars['HPCX_HOME'].append('')
            init_vars['PATH'].append('ompi/tests/imb')
            init_vars['PKG_CONFIG_PATH'].append('sharp/lib/pkgconfig')
            init_vars['PKG_CONFIG_PATH'].append('ucx/lib/pkgconfig')
            init_vars['MANPATH'].append('ompi/share/man')
            init_vars['PMIX_INSTALL_PREFIX'].append('ompi')

            # Generate setenv or prepend_path module function depending on environment variable name
            # For variables in append_var_keys, prepend_path will be used
            prepend_var_keys = ['PATH', 'LD_LIBRARY_PATH', 'LIBRARY_PATH', 'CPATH', 'PKG_CONFIG_PATH', 'MANPATH']
            # Sort variables alphabetically in the generated module
            for var in sorted(init_vars.keys()):
                paths = init_vars[var]
                if (var in prepend_var_keys) or (len(paths) > 1):
                    for path in paths:
                        extravars += self.module_generator.prepend_paths(var, path)
                else:
                    for path in paths:
                        extravars += self.module_generator.set_environment(var, path, relpath=True)
        return extravars

    def make_module_extend_modpath(self):
        """
        Custom MODULEPATH extension for AzureMPI.
        Use version specified in the easyconfig file instead of actual MPI version.
        """

        # Temporarily set switch back to version specified in easyconfig file (e.g., "system")
        self.cfg['version'] = self.orig_version

        # Retrieve module path extensions
        res = super(AzureMPI, self).make_module_extend_modpath()

        # Reset to actual MPI version (e.g., "2.0.2")
        self.cfg['version'] = self.mpi_version

        return res
