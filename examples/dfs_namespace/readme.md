# Setting up a DFS Namespace with multiple ANF volumes

This example sets up Active Directory, ANF with two volumes and two VMs: one for the DFS server and another for the client.

To run, set the `location`, `resource_group` and `win_password` and run the the following:

    azhpc-build -c ad-config.json
    azhpc-build -c anf-config.json

Now, everything will be deployed and the remainder of this document provides step-by-step instructions for setting up DFS Namespaces on the `dfs` VM.  Once this is set up the share can be accessed from the client.

## Set up DFS Namespaces to use the ANF volumes

Log in to the `dfs` VM with RDP.

### Install the DFS role

Open server manager

![Setup DFS step 1](images/setup_dfs_01.png?raw=true)

Click on "Add roles and features"

![Setup DFS step 2](images/setup_dfs_02.png?raw=true)

Click on "Next"

![Setup DFS step 3](images/setup_dfs_03.png?raw=true)

Select your sever and click "Next"

![Setup DFS step 4](images/setup_dfs_04.png?raw=true)

Expand "File and Storage Services" and "File and iSCSI Services" and select "DFS Namespaces"

![Setup DFS step 5](images/setup_dfs_05.png?raw=true)

Select to "Add Features" when prompted.
Click "Next" on the wizard until you get to "Install"

![Setup DFS step 6](images/setup_dfs_06.png?raw=true)

Click "Install"

### Configure DFS

Open the "DFS Management" application (this will be available once the DFS role has been installed).

![Configure DFS step 1](images/configure_dfs_01.png?raw=true)

Right click on "Namespaces" and choose "New Namespace…"

![Configure DFS step 2](images/configure_dfs_02.png?raw=true)

Enter the server that will host the namespace ("dfs" in my case) and click "Next"

![Configure DFS step 3](images/configure_dfs_03.png?raw=true)

Enter the namespace name and click "Next"

![Configure DFS step 4](images/configure_dfs_04.png?raw=true)

Choose "Domain-based namespace" and click on "Next".

![Configure DFS step 5](images/configure_dfs_05.png?raw=true)

Then click "Create".

### Create DFS folders
Expand "Namespaces" and right-click on the new namespace that was created, and choose "New Folder…"

![Create DFS folders 1](images/create_dfs_folders_01.png?raw=true)

Set the "Name" and the "Folder targets" to be an ANF volume. Then click "OK".

Now, repeat for the other volume.