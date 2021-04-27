# EasyBuild

[EasyBuild](https://docs.easybuild.io/en/latest/index.html) is an open source framework written in Python designed to simplify the build, installation and management of scientific software on HPC systems. The main target is to provide a flexible solution to build highly optimized software stacks in a reproducible and fully automated way and organize them to allow co-existence of different versions of compilers, libraries and end-user software. Since software is built with all its required dependencies (including compilers), the stacks dependency to the libraries available in the underlying OS is minimal with the exception of glibc, OpenSSL and OFED.

[**Toolchains**](https://docs.easybuild.io/en/latest/Concepts_and_Terminology.html#toolchains) represent the fundation of the EasyBuild software stack organization. A toolchain is defined as the set of compilers and libraries (MPI and numerical) used to build software. The most widely adopted toolchains are the following [common toolchains](https://docs.easybuild.io/en/latest/Common-toolchains.html#common-toolchains):
* `foss`: free and open source software (GCC, OpenMPI, OpenBLAS, ScaLAPACK, FFTW)
* `intel`: based on Intel compilers and libraries (Intel Compiler, Intel MPI, Intel MKL)

`system` is a special "empty" toolchain that uses the compilers and libraries provided by the OS.

The definition of a specific software build procedure is coded in a Python module called [**easyblock**](https://docs.easybuild.io/en/latest/Implementing-easyblocks.html). Such procedures are generic, i.e. they do not provide details on the software version, toolchain to use and so on.

The remaining information regarding software version, toolchain and all the other settings required to build a given software are included in a text file called [**easyconfig**](https://docs.easybuild.io/en/latest/Writing_easyconfig_files.html) file. All information are provided as key-value pairs. It also provides all the information required to determine the generate module file name according to the configured [module naming scheme](https://easybuilders.github.io/easybuild-tutorial/2021-lust/module_naming_schemes).

## Prerequisites

* GNU/Linux OS
* Python 2.6, 2.7 or >=3.5
* [Environment Modules (TCL/C)](http://modules.sourceforge.net/) or [Lmod](https://lmod.readthedocs.io/en/latest/index.html)

The provided installation script will use latest Python 3 available with the chosen distribution. Lmod is used as environment modules manager due to its larger feature set compared to Environment Modules.

## Installation

1. Install Lmod:
   ```
   $ ./lmod_install [default_module_path]
   ```
   A custom default module path can be passed as argument (default: `/apps/EasyBuild/modules/all/Core`).

   Lmod must be installed on all cluster nodes to provide access to the software stack.

2. Install EasyBuild:
   ```
   $ ./easybuild_install [stack_root_path]
   ```
   A custom stack root path can be provided as argument (default: `/apps`).
   
   **If installing the EasyBuild stack in a shared file system, this step must be executed only once from a single node.**

3. Open a new terminal or source `/etc/profile` to enable Lmod and check that the EasyBuild module is present and the framework is fully functional:
   ```
   $ ml av
   --------------- /apps/EasyBuild/modules/all/Core ---------------
      EasyBuild/4.3.4 (L)

     Where:
      L:  Module is loaded

   Use "module spider" to find all possible modules and extensions.
   Use "module keyword key1 key2 ..." to search for all possible modules matching any of the "keys".

   $ ml EasyBuild

   $ eb --version
   This is EasyBuild 4.3.4 (framework: 4.3.4, easyblocks: 4.3.4) on host headnode.
   ```

## Configuration

The initial EasyBuild installation is configured as follows:
* Use [**rpath**](https://medium.com/obscure-system/rpath-vs-runpath-883029b17c45) to include path of required shared libraries in header of executables and library files. This prevents breaking dependency resolution at runtime due to `LD_LIBRARY_PATH` pollution.
* Modules are organized according to the **hierarchical module naming scheme**.
* Use [**minimal toolchains**](https://docs.easybuild.io/en/latest/Manipulating_dependencies.html#using-minimal-toolchains-for-dependencies) for software dependencies resolution.
* Force sources archives **checksum check** before building.
* Use [**`depends_on`**](https://docs.easybuild.io/en/latest/Manipulating_dependencies.html#using-minimal-toolchains-for-dependencies) in Lmod modules to automatically unload unused dependency modules.
* [**Purge modules**](https://docs.easybuild.io/en/latest/Detecting_loaded_modules.html#purge-run-module-purge-to-clean-environment-of-loaded-modules) from environment at build time to prevent cross-linking with previously loaded libraries.
* Print **full installation output trace** for better build debugging.
* [**Use existing modules**](https://docs.easybuild.io/en/latest/Manipulating_dependencies.html#taking-existing-modules-into-account) to determine which dependencies are already installed.
* Use `/tmp` as scratch directory for building software.
* Zip generated log files to help slow down the universe's growing entropy.

The configuration can be customized by editing: `<stack_root_path>/EasyBuild/easybuild.d/easybuild.cfg`. 

Refer to the [EasyBuild configuration documentation](https://docs.easybuild.io/en/latest/Configuration.html) and the [EasyBuild options documentation](https://docs.easybuild.io/en/latest/version-specific/help.html) for any additional information.

## Utilization

### Software optimization

**EasyBuild by default instructs the compilers to optimize the code for the highest instruction set supported by the build host CPU architecture.**

Ensure you are logged into a VM with the architecture you want to optimize the generated code for. 

If you are adding software to an existing stack, ensure that the VM has the same architecture of the one for which the stack has been optimized.

A different target architecture can be specified by using the `--optarch` option. Refer to the [EasyBuild documentation](https://docs.easybuild.io/en/latest/Controlling_compiler_optimization_flags.html#controlling-compiler-optimization-flags) for more information.

**Be aware that using `--optarch` does not guarantee that the build will be executed with the intended compiler flags since some build systems will autodetect the underlying architecture.** Hence why building on a VM with the target CPU architecture is strongly recommended.

### Install standard foss toolchain

1. Ensure the build VM has the desired CPU architecture (see [Software optimization](#software-optimization)).

2. Load the EasyBuild module:
   ```
   $ module load EasyBuild
   ```

3. Search all the available `foss` toolchain versions:
   ```
   $ eb --search ^foss-
   ```

4. Build the desired toolchain version and all its dependencies recursively by specifying the corresponding easyconfig file name:
   ```
   $ eb -r foss-2020a.eb
   ```
   This step will require about 3.5 hours on an HB60rs VM.

### Install custom foss toolchain containing system HPC-X

The following steps will illustrate how to install a custom AzureMPI easyblock and a set of modified `foss` toolchain easyconfig files that will override the default ones provided by EasyBuild to use the Nvidia HPC-X already installed in the Azure marketplace HPC image.

Since all the names of the modules in the toolchain are not modified from the original ones in the `foss` toolchain, all sofwtare available in EasyBuild will be compatible with the new toolchain without modifications.

1. Run the AzureMPI easyblock and custom `foss` easyconfig installation script:
   ```
   $ ./azurempi_install.sh
   ```

2. Check that the `foss-2020a` toolchain now includes `OpenMPI-system` from the `custom_easyconfigs` directory:
   ```
   $ ml EasyBuild
   $ eb foss-2020a.eb -D | grep OpenMPI-system
    * [ ] $CFGS/custom_easyconfigs/OpenMPI-system-GCC-9.3.0.eb (module: Compiler/GCC/9.3.0 | OpenMPI/system)
   ```
   If EasyBuild robot still picks up the original `OpenMPI` easyconfig check the following:
   * The `<stack_root_path>/EasyBuild/custom_easyconfigs` directory should contain:
     ```
     foss-2020a.eb
     gompi-2020a.eb
     OpenMPI-system-GCC-9.3.0.eb
     ```
   * The `<stack_root_path>/EasyBuild/custom_easyblocks` directory should contain:
     ```
     azurempi.py
     ```
   * The EasyBuild configuration should show:
     ```
     $ egrep 'include-easyblocks|robot-paths' <stack_root_path>/EasyBuild/easybuild.d/easybuild.cfg 
     include-easyblocks = <stack_root_path>/EasyBuild/custom_easyblocks/azurempi.py
     robot-paths = <stack_root_path>/EasyBuild/custom_easyconfigs:
     ```
     **Check that the `custom_easyconfigs` directory is followed by a colon. This instructs EasyBuild to prepended it to the default robot search path.** In this way during dependency resolution the custom easyconfigs will be found and selected for installation before the default ones shipped with EasyBuild.

3. Install the custom `foss` toolchain:
   ```
   $ eb foss-2020a.eb -r
   ```

**NOTE:** Currently only the *foss-2020a* toolchain version is provided. To add a different toolchain version, simply create the corresponding easyconfig files in `<stack_root_path>/EasyBuild/custom_easyconfigs`.
