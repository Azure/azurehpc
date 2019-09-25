param (
    [Parameter(Mandatory=$true)][string]$nfs_server
 )


# Installing NFS client
Enable-WindowsOptionalFeature -Online -FeatureName "ClientForNFS-Infrastructure" -All

# Set UID/GID to 1001 which is the hpcuser one
#reg add HKLM\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default /v AnonymousUid /t REG_DWORD /d 0x3E9 /f
#reg add HKLM\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default /v AnonymousGid /t REG_DWORD /d 0x3E9 /f

# restart the NFS Client service
#net stop NfsClnt
#net start NfsClnt

# Mount Y for Apps and Z for Data
New-PSDrive -Name "Y" -PSProvider "FileSystem" -Root "\\$nfs_server\share\apps" -Persist
New-PSDrive -Name "Z" -PSProvider "FileSystem" -Root "\\$nfs_server\share\data" -Persist
