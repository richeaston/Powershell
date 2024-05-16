Clear-host
$results = @()
$wingetOutput = (winget list) -split '[\r\n]'
$wingetOutput | ForEach-Object {
    if (!($_ -like '*  - \ |  *' -or $_ -like '   - \ *' -or $_ -like '   - *' -or $_ -like '*upgrades available' -OR $_ -like '*-*' -or $_ -eq $null -or $_ -eq '' )) {
        if ($_.Startswith("Name")) {
            $id = $_.indexof('Id')
            $Ver = $_.indexof('Version')
            $source = $_.indexof('Source')
        }
        else {
            if ($_ -ne $null -and $_ -ne " ") {
                $item = [PSCustomObject]@{
                    Name    = $_.Substring(0, $id).TrimEnd()
                    ID      = $_.Substring($id, ($ver - $id)).TrimEnd()
                    Version = $_.Substring($ver, ($source - $ver)).TrimEnd()
                    Source  = $_.Substring($source, ($_.length - $source)).TrimEnd()
                }
                if ($item.source -eq 'winget' -or $item.source -eq 'msstore') {
                    $results += $Item
                }
            }    
        }
    }

}
if (test-path .\My-Installed-apps.csv) {remove-item -Path .\My-Installed-apps.csv -force}
$results | export-csv ".\My-Installed-apps.csv" -NoClobber -NoTypeInformation -Force