# Deploy Azure Bastion for SSH and RDP connections to dedicated jumpbox VMs

This example will create a Bastion service to connect to a Linux jumpbox via SSH and a Windows VM via RDP. All VMs are configured without public IP for maximum security.
Additionally, the following components are installed in the Linux jumpbox using a cloud-init script:
* git
* jq
* AzureHPC
* azcopy
* azcli

The Linux jumpbox supports CentOS and Ubuntu images.

## Step 1 - Install and initialize AzureHPC

Clone the `azhpc` repository and source the `install.sh` script.

```
git clone https://github.com/Azure/azurehpc.git
source azurehpc/install.sh
```

## Step 2 - Initialize the project

To start you need to copy this directory in the desired working location and update the `variables.json` file with the desired parameters.

| Variable                     | Value                                                                   |
|------------------------------|-------------------------------------------------------------------------|
| **resource_group**           | The resource group to put the resources                                 |
| **location**                 | Azure region to deploy resources                                        |
| **vnet_ip_range**            | IP address range in CIDR notation for Bastion VNet                      |
| **default_subnet_ip_range**  | IP address range in CIDR notation for VMs subnet                        |
| **bastion_subnet_ip_range**  | IP address range in CIDR notation for Bastion subnet                    |
| **jumpbox_image**            | CentOS or Ubuntu marketplace image for Linux jumpbox                    |
| **key_vault**                | Unique name to assign to Key Vault                                      |
| **secret_name**              | **DO NOT MODIFY** - Name of the secret storing Windows VM user password |

Then run the `init.sh` script to automatically create the `prereqs.json` and `config.json` configuration files:

```
./init.sh
```

## Step 3 - Create the Key Vault and secret

Before deploying the VMs, a Key Vault must be created containing the future Windows VM password as secret.
This is done by AzureHPC through the `prereqs.json` configuration file. Here is the command:

```
azhpc-build --no-vnet -c prereqs.json
```

## Step 4 - Create Bastion and jumpbox VMs

To start the Bastion and jumpbox VMs deployment execute the following command:

```
azhpc-build
```

Allow about 15 minutes to completion.

## Step 5 - Access the Linux jumpbox via SSH

### From local shell terminal

The provided `bastion_ssh_jumpbox.sh` script allows to easily access the jumpbox VM via SSH.

Simply run the script to log into the jumpbox VM:

```
./bastion_ssh_jumpbox.sh
```

### From Azure Portal

You can also use the Azure Portal to login to the jumpbox VM via Bastion.

Locate the `bastion-jumpbox` VM on the Azure portal and click on "Connect" menu button. Select the "Bastion" option.

![Alt text](/examples/bastion/images/jumpbox_connect.png?raw=true "Jumpbox Connect menu button")

In the Bastion pane type `hpcadmin` in the "Username" field and select "SSH Private Key from Local File" to provide the `hpcadmin_id_rsa` private key created by AzureHPC in the directory where `azhpc-build` has been executed.

![Alt text2](/examples/bastion/images/jumpbox_bastion_ssh.png?raw=true "Azure Bastion Linux SSH")

After selecting "Connect" at the bottom of the pane, a new browser tab will open with the jumpbox Linux terminal.

## Step 6 - Access the Windows VM via RDP

The Windows VM can be accessed via RDP exclusively from Azure Portal.

Locate the `bastion-winbox` VM on the Azure portal and click on "Connect" menu button. Select the "Bastion" option.

![Alt text3](/examples/bastion/images/winbox_connect.png?raw=true "Windows VM Connect menu button")

In the Bastion pane type `hpcadmin` in the "Username" field and select "Password from Azure Key Vault" as authentication type. In the three new drop down menus select the Key Vault deployed by AzureHPC and finally `WinVM-hpcadmin` as secret name.

![Alt text4](/examples/bastion/images/winbox_bastion_rdp.png?raw=true "Azure Bastion Windows RDP")

After selecting "Connect" at the bottom of the pane, the Windows desktop will be accessible in a new browser tab.
