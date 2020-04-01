# Deploy an initialize a Grafana server
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
 - Add port 3000 to the NSG of the grafana server
 - access the portal thru the URL : **http://[grafana server fqdn]:3000/**
 - Authenticate with the **admin** user and the password stored into your KeyVault


