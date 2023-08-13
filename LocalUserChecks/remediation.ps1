Clear-Host
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#check local admin accounts

invoke-webrequest -uri "[url to sas storage excluded.txt]" -OutFile "c:\windows\temp\excluded.txt"
$excludedmembers = get-content c:\windows\temp\excluded.txt

$localadmins = get-localgroupmember -Group Administrators | Where-Object { $_.PrincipalSource -ne 'Local' -and $_.objectclass -eq 'user' -and $_.name -ne "$env:userdomain\Domain Admins" } | Select-Object -ExpandProperty Name
foreach ($user in $localadmins) {
    if ($excludedmembers -like $user) {
        Write-output "$user is excluded, skipping" 
    }
    else {
        Write-output "$user shouldn't be in local admins, removing" 
        Remove-LocalGroupMember -Group administrators -Member $user -Verbose
    }
}
exit 0
remove-item C:\Windows\temp\excluded.txt -Force
