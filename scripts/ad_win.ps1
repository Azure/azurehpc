#install AD 
param (
    [Parameter(Mandatory=$true)][string] $ad_domain,
    [Parameter(Mandatory=$true)][string] $ad_user,
    [Parameter(Mandatory=$true)][string] $ad_password
    )

Write-Output $ad_domain
Write-Output $ad_user
Write-Output $ad_password

Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
Install-WindowsFeature DNS -IncludeAllSubFeature -IncludeManagementTools
Install-ADDSForest `
   -CreateDnsDelegation:$false `
   -DomainName $ad_domain `
   -InstallDns `
   -DomainMode Win2012R2 `
   -ForestMode Win2012R2 `
   -DatabasePath C:\Windows\NTDS `
   -SysvolPath C:\Windows\SYSVOL `
   -LogPath C:\Windows\Logs `
   -NoRebootOnCompletion:$false `
   -Force `
   -SafeModeAdministratorPassword (ConvertTo-SecureString $ad_password -AsPlainText -Force) > D:\domain.log
