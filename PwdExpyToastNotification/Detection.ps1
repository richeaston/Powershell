# Displays password expiry toast notifcation if pwd expiry 14 days or 5
# Written by Richard Easton
# requires the following PS modules on the endpoint MSOnline, Azure
# so make sure they present in "c:\program files\Windows Powershell\Modules"
# and make sure you tick the "Run this script using the logged-on credentials"
# and "run script in 64-bit Powershell" otherwise it will error as x86 stores the mdoules in a different location


Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Confirm:$false -force

try
{
    Get-MsolDomain -ErrorAction Stop > $null
}
catch 
{
    if ($cred -eq $null) {
    $username = "[read only service account]"
    $KeyFile = "[path to AES key file]"  #can be read only blob storage
    $Key = Get-Content $KeyFile
    $creds = "[path to encrypted password]"  #can be read only blob storage
    $pwd = Get-Content $creds | ConvertTo-SecureString -Key $Key
    $cred = new-object System.Management.Automation.PSCredential ( $username , $pwd )
    #you can use azure key vault for this ;)
    
}
    Write-Output "Connecting to Office 365..."
    Connect-MsolService -Credential $cred
}


try {
    $maxpwdage = 90
    $user = Get-MsolUser -SearchString $env:USERNAME -erroraction SilentlyContinue | select DisplayName, LastPasswordChangeTimeStamp,@{Name=”PasswordAge”;Expression={(Get-Date)-$_.LastPasswordChangeTimeStamp}}  | sort-object PasswordAge -descending
    $expirydays = ($maxpwdage - $($user.PasswordAge.Days))
    $integer = $expirydays -replace "-",""
    $days = [int]$integer

    if ($($days) -le 14) {
        Write-output "Warning!, $($user.Displayname)'s Password is going to expire in $days days, sending Toast Notification"
        #call toast
        exit 1
    } else {
        Write-output "$($user.Displayname)'s password is fine, $days left, last set $(get-date($($user.LastPasswordChangeTimestamp)) -format "dd/MM/yyyy HH:mm:ss")"
        [Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted -Confirm:$false -force
        exit 0
    }
}
catch {
    Write-Output "$env:USERNAME not found, please check and try again!`n`n`$($error)"
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted -Confirm:$false -force
    [Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()
}


