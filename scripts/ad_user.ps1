#install AD 
param (
    [Parameter(Mandatory=$true)][string] $ad_domain,
    [Parameter(Mandatory=$true)][string] $ad_user,
    [Parameter(Mandatory=$true)][string] $ad_password
    )

#$ProgressPreference = 'SilentlyContinue'

Write-Output $ad_domain >> D:\user.log
Write-Output $ad_user >> D:\user.log

Set-ADGroup “Domain Users” -Replace @{gidNumber=”25000”}

New-ADUser `
   -Name "hpcwinuser" `
   -GivenName "hpcwinuser" `
   -Surname "hpcwinuser" `
   -SamAccountName "hpcwinuser" `
   -UserPrincipalName "hpcwinuser@$ad_domain" `
   -AccountPassword(ConvertTo-SecureString $ad_password -AsPlainText -Force) `
   -Enabled $true >> D:\user.log
Set-ADUser -identity hpcwinuser -add @{gidnumber="25000" ; uidnumber="25000" ; unixHomeDirectory=”/share/home/hpcwinuser”} >> D:\user.log

