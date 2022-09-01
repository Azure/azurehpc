# Deploy Azure Bastion for SSH and RDP connections to dedicated jumpbox

This example will create a Linux jumpbox and a Windows VM without public IP. They can be accessed via SSH and RDP respectively through the co-deployed Azure Bastion.
Additionally, the following components are installed in the jumpbox using a cloud-init script:
* git
* jq
* AzureHPC
* azcopy
* azcli

## Initialize the project

To start you need to copy this directory and update the `config.json`. AzureHPC provides the `azhpc-init` command that can automatically makes a copy of the directory and substitutes the unset variables. First run the command with the `-s` parameter to see which variables need to be set:

```
azhpc-init -c $azhpc_dir/examples/bastion -d bastion -s
```

The variables can be then set with the `-v` option. Multiple variables can be specified as comma separated list. The `-d` option is required and will create a new directory (`my_bastion` in the example below) for you. For example:

```
azhpc-init -c $azhpc_dir/examples/bastion -d my_bastion -v resource_group=azurehpc-bastion,location=eastus,win_password=9S5zvbb4E9Sw,key_vault=kv-bastion
```

`azhpc-init` also allows to update variables even if they are already set. For example, in the command below we also change the bastion name to `mybastion` and the SKU to `Standard_HC44rs`:

```
azhpc-init -c $azhpc_dir/examples/bastion -d my_bastion -v resource_group=azurehpc-bastion,location=eastus,win_password=9S5zvbb4E9Sw,key_vault=kv-bastion,vm_type=Standard_HC44rs,bastion_name=mybastion
```

## Create the resources

In the newly created directory run `azhpc-build` to start the deployment:

```
cd my_bastion
azhpc-build
```

Allow about 15 minutes to completion.

## Access the Linux jumpbox via SSH

### From local shell terminal

The provided `bastion_ssh_jumpbox.sh` script allows to easily access the jumpbox VM via SSH.
If you modified the name of the jumpbox VM in the `config.json` file, use your preferred editor to update the script.

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

## Access the Windows VM via RDP

The Windows VM can be accessed via RDP exclusively from Azure Portal.

Locate the `bastion-winbox` VM on the Azure portal and click on "Connect" menu button. Select the "Bastion" option.

![Alt text3](/examples/bastion/images/winbox_connect.png?raw=true "Windows VM Connect menu button")

In the Bastion pane type `hpcadmin` in the "Username" field and select "Password from Azure Key Vault" as authentication type. In the three new drop down menus select the Key Vault deployed by AzureHPC and finally `WinVM-hpcadmin` as secret name.

![Alt text4](/examples/bastion/images/winbox_bastion_rdp.png?raw=true "Azure Bastion Windows RDP")

After selecting "Connect" at the bottom of the pane, the Windows desktop will be accessible in a new browser tab.
