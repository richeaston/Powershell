[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
clear-host 
Invoke-WebRequest [url of your exclusions file] -OutFile c:\temp\exclusions.txt
$exclusions = get-content "c:\temp\exclusions.txt" -Exclude $null
$Upgraderesult = (winget upgrade) -split ('[\r\n]')
$Upgraderesult.count
$results = @()

$upgraderesult | foreach-object {
    if (!($_ -like '*  - \ |  *' -or $_ -like '   - \ *' -or $_ -like '   - *' -or $_ -like '*upgrades available' -OR $_ -like '-*' )) {
        if ($_.Startswith("Name")) {
            $id = $_.indexof("Id")
            $Ver = $_.indexof("Version")
            $Avail = $_.indexof("Available")
            $source = $_.indexof("Source")
        }
        else {
            $item = [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                Domain = $env:USERDOMAIN
                Name      = $_.Substring(0, $id).TrimEnd()
                ID        = $_.Substring($id, ($ver - $id)).TrimEnd()
                Version   = $_.Substring($ver, ($Avail - $ver)).TrimEnd()
                Available = $_.Substring($avail, ($source - $avail)).TrimEnd()
                Source    = $_.Substring($source, ($_.length - $source)).TrimEnd()
                Excluded  = ($exclusions -contains $_.Substring($id, ($ver - $id)).TrimEnd())
            }
                $results += $Item
        }
    }
}
clear-host
#$results  | ft -AutoSize
$ToUpgrade = @()
foreach ($app in ($results )) {
    if (!($exclusions -contains $($app.id) -or $null -eq $($app.Name))) { 
        $ToUpgrade += $app
    }
}


if ($ToUpgrade.count -gt 0) {
  Write-output ($ToUpgrade | sort-object Name | select-object Computername, Domain, Name, ID, Version, Available, Source, Excluded -Unique | Format-Table -AutoSize )
  $ToUpgrade | sort-object Name | Where-Object {$_.source -match 'Winget'} | select-object Computername, Domain, Name, ID, Version, Available, Source, Excluded -Unique | Export-Csv -Path "\\gaguxbpdq01\TPA-Audit`$\Audit.csv" -NoClobber -NoTypeInformation -Append
} Else {
    Write-host "No Apps to upgrade :)" -ForegroundColor Green
}

