#install RGS
param (
    [Parameter(Mandatory=$true)][string] $lic_url,
    [Parameter(Mandatory=$true)][string] $sw_url
)

$ProgressPreference = 'SilentlyContinue'

Write-Output $lic_url
Write-Output $sw_url


Set-Location C:\Windows\Temp
Invoke-WebRequest -OutFile C:\Windows\rgs_trial.lic $lic_url
Invoke-WebRequest -OutFile SenderSetup64.exe $sw_url
.\SenderSetup64.exe /z"/autoinstall /agreetolicense /clipboard /rgslicensefile=C:\Windows\rgs_trial.lic /noreboot" -Wait