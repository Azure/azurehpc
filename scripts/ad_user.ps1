#install AD 
param (
    [Parameter(Mandatory=$true)][string] $ad_domain,
    [Parameter(Mandatory=$true)][string] $ad_user,
    [Parameter(Mandatory=$true)][string] $ad_password
    )

#$ProgressPreference = 'SilentlyContinue'

Write-Output $ad_domain
Write-Output $ad_user
Write-Output $ad_password

New-ADUser `
   -Name "hpcuser" `
   -GivenName "hpcuser" `
   -Surname "hpcuser" `
   -SamAccountName "hpcuser" `
   -UserPrincipalName "hpcuser@$ad_domain" `
   -AccountPassword(ConvertTo-SecureString $ad_password -AsPlainText -Force) `
   -Enabled $true > D:\user.log
