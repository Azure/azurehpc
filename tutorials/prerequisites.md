## Open your Cloud Shell environment (or any other Bash Shell)

Clone the **azurehpc** repo

```
git clone https://github.com/Azure/azurehpc.git
```

If you don't have a Key Vault, create one

```
az group create --name keyvault-rg --location <location>
az keyvault create --name azhpc-vault --resource-group keyvault-rg
``` 

If not done, create a password and store it in Key Vault

```
secret='yoursecret'
az keyvault secret set --vault-name azhpc-vault --name "winadmin-secret" --value $secret
```
You can access your keyvault secret from a config.json file using the following format (secret.KeyVaultName.key)

Initialize your working directory, fill up the missing parameters

```
. azurehpc/install.sh
```

`azhpc_dir` is now in your environment. This is how you will reference the files/directories.  You should create a new directory for you projects.

If you are running the tutorials make sure you have quota to run them. You can find details on the resources used in the diagram.png file in the same folder as the tutorial (e.g. [here](https://github.com/Azure/azurehpc/blob/master/tutorials/cfd_workflow/diagram.png)).

If you are running in WSL you may want to review [this step](https://github.com/Azure/azurehpc/#windows-subsystem-for-linux).
