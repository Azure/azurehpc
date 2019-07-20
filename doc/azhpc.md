---
theme: night
revealOptions:
    slideNumber: true
---

# azhpc

---

## What is azhpc?

* An easy way to create HPC environment
* Single JSON config file
  - Describe resources
  - Sequence of scripts for install
  - Tags to choose where to run scripts

---

## Driven from a JSON config file
#### (and some shell scripts for install)

* Minimal information for cluster set up
  - Setup information
  - VNet dictionary
  - Variables dictionary
  - Resources dictionary
  - Install list

----

## Setup Information

* Location
* Resource group
* Admin user
* Resource name to install from
  - Used to install/connect
  - Requires public IP
  - *Or a resolvable hostname*

----

## VNet Dictionary

* The vnet details:
  - Name
  - Network address (CIDR)
  - Subnet information
    - Dictionary of name to address

----

## Variables Dictionary

* Group variables in the template together
* Use 
* Useful for creating templates to share

----

## Macros in the config

* Replace value with a Variable
  - `variables.<json-path-in-variables>`
* Read from Key Vault:
  - `secret.<vault-name>.<key-name>`
* Generate SAS URL for BLOB Storage
  - `sasurl.<storage-account>.<path>`
* *These can be nested*

----

## Resources Dictionary

* The name is the identifier
* Each resource can be a VM or a VMSS
* Options are for:
  - SKU
  - VM Image
  - Accelerated networking
  - Public IP
  - subnet
  - **Tags**

----

## Install List

* A **list** of scripts to execute
* **Tags** determine which of the resources the scripts run on
* Options
  - Whether to run with `sudo`
  - Pass the VMSS index as an argument
    - *Needed when setting up Lustre OSS*
  - Reboot after script is complete
    - *Handles kernel updates*
* Install script is created
  - Launched from the `install_from` resource

----

## Any restrictions on the scripts?

* They are just shell scripts
  - As many or as few as you'd like
* They could be anything
  - From disabling SE Linux
  - To setting up lustre
* The install list is run sequentially
  - but each step executed in parallel (for resources sharing the same tag)
