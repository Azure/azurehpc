#install TGX
param (
    [Parameter(Mandatory=$true)][string] $lic_url,
    [Parameter(Mandatory=$true)][string] $sw_url
)

$ProgressPreference = 'SilentlyContinue'

Write-Output $lic_url
Write-Output $sw_url

# TGX
Set-Location C:\Windows\Temp
Invoke-WebRequest -OutFile  TGX_Sender.exe $sw_url
Start-Process '.\TGX_Sender.exe' -ArgumentList "/SILENT /SUPPRESSMSGBOXES /LOG /NORESTART REBOOT=ReallySuppress" -Wait
Invoke-WebRequest -OutFile c:\ProgramData\Mechdyne\licenses\TGX.lic $lic_url