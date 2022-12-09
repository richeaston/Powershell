# LogonAsService
Powershell functions to manipulate "Logon As Service" in local Secpol.msc

These functions are to add an account to "Logon As Service" and also display all accounts that have the ability to "Logon As Service"

Function files
Add-LOASGroupMember.ps1

usage: 

Add-LOASGroupMember -accountname [domain\username]

==================================================

Get-LOASGroupMembers.ps1

Usage: 

Get-LOASGroupMembers 

or 

$account = [domain\username]

get-LOASGroupMembers | Where {$_.username -eq $account}

==================================================
