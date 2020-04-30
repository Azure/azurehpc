param (
    [Parameter(Mandatory=$true)][string] $ad_domain,
    [Parameter(Mandatory=$true)][string] $ad_server,
    [Parameter(Mandatory=$true)][string] $ad_admin,
    [Parameter(Mandatory=$true)][string] $ad_password
    )

$dnsip = [System.Net.Dns]::GetHostAddresses($ad_server)[0].IPAddressToString;

Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses "$dnsip","168.63.129.16"

$password = "$ad_password" | ConvertTo-SecureString -asPlainText -Force
$username = "$ad_domain\$ad_admin" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
Add-Computer -DomainName $ad_domain -Credential $credential

$DomainGroup = "Domain Users"
$LocalGroup  = "Remote Desktop Users"
$Computer    = $env:computername

([ADSI]"WinNT://$Computer/$LocalGroup,group").psbase.Invoke("Add",([ADSI]"WinNT://$ad_domain/$DomainGroup").path)

netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes

shutdown.exe /r /t 00
