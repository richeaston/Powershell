Clear-Host
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
 
Write-output "Local Managed Admin account should be: $result"    

if (Get-LocalUser -name $result -ErrorAction SilentlyContinue) {
    Write-output "Local Managed admin account $result present :)"
}
else {
    Write-output "Local Managed admin account $result not present :("
    New-LocalUser -Name $result -Description "Local admin account" -AccountNeverExpires -NoPassword -Verbose | Add-LocalGroupMember Administrators -Verbose
}

#check status of local administrator account
if ((get-localuser -name administrator -ErrorAction SilentlyContinue).Enabled -eq $true) {
    get-localuser -name administrator | Disable-LocalUser 
    Rename-LocalUser -Name Administrator -NewName Dis_Administrator
}
else {
    Write-output "Local administrator account is disabled"
}

#check status of local guest account
if ((get-localuser -name Guest -ErrorAction SilentlyContinue).Enabled -eq $true ) {
    get-localuser -name Guest | Disable-LocalUser 
    Rename-LocalUser -Name Guest -NewName Dis_Guest
}
else {
    Write-output "Local guest account is disabled"
}

$excludedmembers = @("gag\svc-pdq", "*svc-*", "*svc_*", "*\-a*", "$env:userdomain\SVC-LocalAdmins", "GAGlondon\DA - DAS Signon", "gaglondon\DA - Local Admin", "gagho\richard.easton", "gag\re.admin", "gagho\richard.blagg", "gagho\hayden.scott")
$localadmins = get-localgroupmember -Group Administrators | Where-Object { $_.PrincipalSource -ne 'Local' -and $_.objectclass -eq 'user' -and $_.name -ne '$result' } | Select-Object -ExpandProperty Name
foreach ($user in $localadmins) {
    if ($excludedmembers -contains $user) {
        Write-output "$user is excluded, skipping" 
    }
    else {
        Write-warning "$user shouldn't be in local admins, removing" 
        Remove-LocalGroupMember -Group administrators -Member $user -WhatIf -Verbose
    }
}