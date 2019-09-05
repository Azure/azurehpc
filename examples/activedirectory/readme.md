# Use Active Directory for user authentication

To build a usable cluster for a group of users, authentication and authorization has to be set up. The example
here demonstrates how to set up a AD server and how to connect the cluster nodes to it.

First create the config file for the Active Directory Domain Controller
'''
$ azhpc-init -c azurehpc/examples/activedirectory/ad-config.json -d adtest -s
Thu Sep  5 11:38:08 CEST 2019 : variables to set: "-v location=,resource_group=,win_password="
'''
 
And build it....
'''
$ azhpc-init -c azurehpc/examples/activedirectory/ad-config.json -d adtest -v "location=westeurope
,resource_group=ad_demo,win_password=mypassword@1234"
Thu Sep  5 11:40:29 CEST 2019 : creating directory adtest
Thu Sep  5 11:40:29 CEST 2019 : copying config.json to adtest
Thu Sep  5 11:40:29 CEST 2019 : updating file adtest/ad-config.json
$ azhpc-build -c ad-config.json
'''

Now the actual cluster can be initialized and build
'''
$ azhpc-init -c ../azurehpc/examples/activedirectory/config.json -v "location=westeurope,re
source_group=ad_demo,win_password=mypassword@1234"
Thu Sep  5 11:55:45 CEST 2019 : creating directory .
Thu Sep  5 11:55:45 CEST 2019 : copying config.json to .
Thu Sep  5 11:55:45 CEST 2019 : updating file ./ad-config.json
Thu Sep  5 11:55:45 CEST 2019 : updating file ./config.json
$ azhpc-build
'''

While building the cluster, connect to the AD node, and start up the Active Directory Users and Computers manager to add a new user.

![Add Windows User](add_windows_user.png?raw=true)

'''
$ azhpc-connect headnode
Thu Sep  5 12:21:04 CEST 2019 : logging in to headnode (via headnodee10cb4.westeurope.cloudapp.azure.com)
[hpcadmin@headnode ~]$ getent passwd winuser
winuser:*:719201105:719200513:winuser:/share/home/winuser:/bin/bash
'''

and you can login using the supplied password:
'''
[hpcadmin@headnode ~]$ ssh winuser@localhost
winuser@localhost's password:
Creating home directory for winuser.
[winuser@headnode ~]$
'''

Some basic cluster homework:
'''
[winuser@headnode ~]$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/share/home/winuser/.ssh/id_rsa):
Created directory '/share/home/winuser/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /share/home/winuser/.ssh/id_rsa.
Your public key has been saved in /share/home/winuser/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:Lt9Muf0RI61mBLkpliUtEq68Q2t0pTJUkkqfrrY/vLU winuser@headnode
The key's randomart image is:
+---[RSA 2048]----+
|    ..o          |
|  . .+ . . .     |
| . o..o + =      |
|  .oo. + = + .   |
|   .B o S o o +  |
|   o.* o . o o o |
|   o= o . o + .  |
|  o.oo + + =   . |
| ..oooE . + ...  |
+----[SHA256]-----+
[winuser@headnode ~]$
[winuser@headnode ~]$ cp .ssh/id_rsa.pub .ssh/authorized_keys
[winuser@headnode ~]$ pbsnodes -a | grep compu
compu8526000001
     resources_available.vnode = compu8526000001
compu8526000000
     resources_available.vnode = compu8526000000
[winuser@headnode ~]$ ssh compu8526000000
Last login: Thu Sep  5 10:25:49 2019 from 10.2.4.8
[winuser@compu8526000000 ~]$ exit
logout
Connection to compu8526000000 closed.
[winuser@headnode ~]$
'''

And you can submit your first job... 
'''
[winuser@headnode ~]$ qsub -l nodes=2 -- hostname
0.headnode
[winuser@headnode ~]$ ls
STDIN.e0  STDIN.o0
'''


