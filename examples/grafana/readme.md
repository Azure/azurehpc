# Deploy and initialize a Grafana server
![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/grafana?branchName=master)

This example shows how deploy a [Grafana](https://grafana.com/grafana/) server and configure [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/) on monitored machines.


The configuration file requires the following variables to be set:

| Variable                | Description                                  |
|-------------------------|----------------------------------------------|
| location                | The location of resources                    |
| resource_group          | The resource group for the project           |
| vm_type                 | Azure GPU VM full name (NC or ND series)     |
| key_vault               | Keyvault to store the GrafanaPassword secret |

> Note : Create an Azure Key Vault and store the Grafana Password in the secret named _GrafanaPassword_

Once deployed:
 - access the portal thru the URL : **http://[grafana server fqdn]:3000/**, which can be retrieved by running `azhpc-get fqdn.grafana`
 - Authenticate with the **admin** user and the password stored into your KeyVault, which can be retrieved by running `azhpc-get secret.{{variables.key_vault}}.GrafanaPassword`
 - Access the dashboard thru the left meny **Dashboards/Manage** and then select "Telegraf : system dashboard"

> Note : To monitor other VMs, just add the **telegraf** tag to your resources and its associated install script and configuration file as specified the in the configuration file

```json
        {
            "script": "install-telegraf.sh",
            "tag": "telegraf",
            "sudo": true,
            "args": [
                "<grafana server or ip address>",
                "azhpc",
                "secret.{{variables.key_vault}}.GrafanaPassword",
                 "telegraf-default.conf"
             ],
             "deps" : ["telegraf-default.conf"]
        }
```
