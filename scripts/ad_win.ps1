#install AD 
param (
    [Parameter(Mandatory=$true)][string] $ad_domain,
    [Parameter(Mandatory=$true)][string] $ad_user,
    [Parameter(Mandatory=$true)][string] $ad_password
    )

Write-Output $ad_domain
Write-Output $ad_user
Write-Output $ad_password

#AD
Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools >> D:\domain.log
#DNS
Install-WindowsFeature DNS -IncludeAllSubFeature -IncludeManagementTools >> D:\domain.log
#NFS
Install-WindowsFeature FS-NFS-Service -IncludeManagementTools >> D:\domain.log
#SSH
#Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
#Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
#Install-Module -Force OpenSSHUtils -Scope AllUsers
#Set-Service -Name ssh-agent -StartupType ‘Automatic’
#Set-Service -Name sshd -StartupType ‘Automatic’
#Start-Service ssh-agent
#Start-Service sshd
#become AD
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
   -SafeModeAdministratorPassword (ConvertTo-SecureString $ad_password -AsPlainText -Force) >> D:\domain.log
# Set-NfsMappingStore -EnableADLookup $true >> D:\domain.log
shutdown.exe /r /t 00
