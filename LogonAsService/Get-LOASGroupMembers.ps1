function Get-LOASGroupMembers() {
    
    Clear-Host
    $tmp = [System.IO.Path]::GetTempFileName()

    Write-Host "Export current Local Security Policy" -ForegroundColor DarkCyan
    secedit.exe /export /cfg "$($tmp)" 
    
    
    $c = Get-Content -Path $tmp 
    $currentSetting = ""
    
    foreach($s in $c) {
	    if( $s -like "SeServiceLogonRight*") {
    		$x = $s.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
	    	$currentSetting = $x[1].Trim()
	    }
    }
    Write-host "`nThe following user accounts have 'Logon As Service' rights`n" -ForegroundColor DarkCyan
    
    $sids = $currentSetting.split(',')
    $users = @()
    foreach ($s in $sids) {
        $sid = $s.replace("*","")
        $objSID = New-Object System.Security.Principal.SecurityIdentifier("$sid")
        $objUser = $objSID.Translate( [System.Security.Principal.NTAccount])
        $user = [pscustomobject] @{
            username = $objUser.Value
            sid = $sid
        }
        Write-host $user.username ":" $user.sid
        $users += $user
        
    }
    write-host
}
<# usage options
Get-LOASGroupMembers

or 

$account = "Domain\username"
Get-LOASGroupMembers | where {$_.username -eq $account}

#>

Get-LOASGroupMembers


