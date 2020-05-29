#install NFS share 
param (
    [Parameter(Mandatory=$true)][string] $ad_domain,
    [Parameter(Mandatory=$true)][string] $ad_user,
    [Parameter(Mandatory=$true)][string] $ad_password
    )

Write-Output $ad_domain
Write-Output $ad_user
Write-Output $ad_password

Set-NfsMappingStore -EnableADLookup $true >> D:\domain.log

mkdir D:\shares\nfs
New-NfsShare -name nfs -Path d:\shares\nfs -authentication sys -EnableUnmappedAccess $False -EnableAnonymousAccess $False -permission Readwrite
New-SmbShare -name nfs -Path d:\shares\nfs -FullAccess "Domain Users"

