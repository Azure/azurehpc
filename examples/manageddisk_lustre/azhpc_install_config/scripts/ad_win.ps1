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


#cd C:\Windows\Temp
#Invoke-WebRequest -OutFile C:\Windows\rgs_trial.lic $lic_url
#Invoke-WebRequest -OutFile SenderSetup64.exe $sw_url
#.\SenderSetup64.exe /z"/autoinstall /agreetolicense /clipboard /rgslicensefile=C:\Windows\rgs_trial.lic /noreboot" -Wait
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
#New-ADUser `
#   -Name "hpcuser" `
#   -GivenName "hpcuser" `
#   -Surname "hpcuser" `
#   -SamAccountName "hpcuser" `
#   -UserPrincipalName "hpcuser@$ad_domain" `
#   -AccountPassword(ConvertTo-SecureString $ad_password -AsPlainText -Force) `
#   -Enabled $true > D:\user.log
