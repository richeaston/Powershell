Clear-Host
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Require Admin Privileges
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) 
{ throw "This script must be run as an administrator." }

$bad = 0

invoke-webrequest -uri "[url to sas storage excluded.txt]" -OutFile c:\Windows\temp\excluded.txt
$excludedmembers = get-content C:\Windows\temp\excluded.txt

$localadmins = get-localgroupmember -Group Administrators | Where-Object { $_.PrincipalSource -ne 'Local' -and $_.objectclass -eq 'user' -and $_.name -ne "$env:userdomain\Domain Admins" } | Select-Object -ExpandProperty Name
foreach ($user in $localadmins) {
    if ($excludedmembers -like $user) {
        Write-output "$user is excluded, skipping" 
    }
    else {
        Write-Output "$user shouldn't be in local admins, removing"
        $bad++ 
        #Remove-LocalGroupMember -Group administrators -Member $user -WhatIf -Verbose
    }
}

if ($bad -gt 0 ) {
    exit 1    
} else {
    exit 0
}

remove-item C:\Windows\temp\excluded.txt
