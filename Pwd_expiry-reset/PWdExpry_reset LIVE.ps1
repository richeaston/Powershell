import-module -name ActiveDirectory
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

#create log file
$date = get-date -Format "dd-MM-yy"
$logfile = "$dir\PWDNEF_$date.log"
if (!(test-path $logfile)) { new-item -Path $dir -name "PWDNEF_$date.log" -ItemType file -Force }

$now = get-date -Format "dd/MM/yy HH:mm:ss"
add-content -Path $logfile -Value "$($now) : Log file initialized"


#variables
$domain = Get-ADDomain | Select -ExpandProperty DistinguishedName
$cutoff = (get-date).AddDays("-14")
$accounts = Get-aduser -Filter * -Properties * -Searchbase $domain |  where {($_.UserPrincipalName -like '*@go-ahead.com*') -and ($_.PasswordNeverExpires -eq $True) -and ($_.PasswordLastSet -lt $cutoff) -and ($_.Enabled -eq 'True') -and ($_.SamAccountName -notlike 'svc*')} | Select SamAccountName, UserPrincipalName, PasswordNeverExpires, PasswordLastSet | sort-object SamAccountName
$exclusions = "$dir\exclusions.txt"

#test for exclusions file
if (!(test-path $exclusions)) { New-item -Path $dir -name "exclusions.txt" -ItemType file -force }
$exclusions = get-content $exclusions


foreach ($user in $accounts) {
    if (!($exclusions -contains $($user.SamAccountName))) {
        Write-host "Processing $($user.SamAccountName)" -ForegroundColor Yellow
        #Set-ADUser -Identity $user.SamAccountName -Replace @{pwdlastset=-1} -verbose
        set-aduser -Identity $user.SamAccountName -PasswordNeverExpires $False -verbose
        $now = get-date -Format "dd/MM/yy HH:mm:ss"
        add-content -Path $logfile -Value "$($now) : Removed PasswordNeverExpires flag from $($user.SamAccountName)"
        Get-aduser -Identity $user.SamAccountName -Properties * | Select SamAccountName, UserPrincipalName, PasswordNeverExpires, PasswordLastSet
    } else {
        $now = get-date -Format "dd/MM/yy HH:mm:ss"
        add-content -Path $logfile -Value "$($now) : $($user.SamAccountName) Excluded"
        Write-host "$($user.SamAccountName) Excluded!`n" -ForegroundColor Magenta
    }
}

$now = get-date -Format "dd/MM/yy HH:mm:ss"
add-content -Path $logfile -Value "$($now) : Script run completed"

