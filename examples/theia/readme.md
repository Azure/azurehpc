# Create a cloud IDE ready to use
![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/theia?branchName=master)

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/theia/config.json)

This provisions and sets up the [Theia IDE](https://theia-ide.org/) browser example.  After running `azhpc-build`, find the FQDN and forward port 3000 to localhost:

    ssh -L 3000:localhost:3000 -i ./azureuser_id_rsa azureuser@<INSERT-FQDN>

You can access the IDE by going to http://localhost:3000 in the browser.