Clear-Host
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Require Admin Privileges
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) 
{ throw "This script must be run as an administrator." }

#check local admin accounts
switch ( $env:USERDOMAIN  ) {
    BRIGHTONBUSES { $result = 'BAH.Admin' }
    EYMS { $result = 'EYMS.Admin' }
    GAGHO { $result = 'GAG.Admin' }
    GOAHEADDUBLIN { $result = 'GAD.Admin' }
    GOEASTANGLIA { $result = 'GEA.Admin' }
    GONORTHEAST { $result = 'GNE.Admin' }
    GONORTHWEST { $result = 'GNW.Admin' }
    GAGLONDON { $result = 'GAL.Admin' }
    GAGPCB { $result = 'PCB.Admin' }
    GAGSG { $result = 'GAS.Admin' }
    OXFORD { $result = 'OXB.Admin' }
    WDBUSCO { $result = 'GSC.Admin' }
}

$bad = 0

Write-output "Local Managed Admin account should be: $result"    

if (Get-LocalUser -name $result -ErrorAction SilentlyContinue) {
    Write-output "Local Managed admin account $result present :)"
}
else {
    Write-output "Local Managed admin account $result not present :("
    New-LocalUser -Name $result -Description "Local admin account" -AccountNeverExpires -NoPassword -Verbose | Add-LocalGroupMember Administrators -Verbose
}

invoke-webrequest -uri "https://d3pl0ywin10.blob.core.windows.net/windows10deploy/Excluded.txt?sp=r&st=2023-04-17T10:12:07Z&se=2123-04-17T18:12:07Z&spr=https&sv=2021-12-02&sr=b&sig=NSnQiqcz4f%2BQw8S9QZ321K1KhLpxybFOqtVf4kWVZac%3D" -OutFile c:\Windows\temp\excluded.txt
$excludedmembers = get-content C:\Windows\temp\excluded.txt

$localadmins = get-localgroupmember -Group Administrators | Where-Object { $_.PrincipalSource -ne 'Local' -and $_.objectclass -eq 'user' -and $_.name -ne '$result' -and $_.name -ne "$env:userdomain\SVC-LocalAdmins" -and $_.name -ne "$env:userdomain\SVC-Rapid7" -and $_.name -ne "$env:userdomain\Domain Admins" } | Select-Object -ExpandProperty Name
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