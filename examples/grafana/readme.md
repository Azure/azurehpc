# Deploy an initialize a Grafana server
This example shows how deploy a [Grafana](https://grafana.com/grafana/) server and configure [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/) on monitored machines.


The configuration file requires the following variables to be set:

| Variable                | Description                                  |
|-------------------------|----------------------------------------------|
| location                | The location of resources                    |
| resource_group          | The resource group for the project           |
| vm_type                 | Azure GPU VM full name (NC or ND series)     |
| key_vault               | Keyvault to store the GrafanaPassword secret |

Pre-Requisites : Create an Azure Key Vault and store the Grafana Password in the secret named GrafanaPassword

