Clear-Host
$gpos = Get-GPO -all | Select-Object DisplayName, Description, GPOStatus | sort-object DisplayName
$array = @()

foreach ($gpo in $gpos){ 
    
    $OUTGPO = [PSCustomObject] @{
        'Name' = $gpo.DisplayName
        'Enabled' = $gpo.GPOStatus
        'Description' = $gpo.Description
    }
    Write-host "Processing " -NoNewline
    Write-host $OUTGPO.Name -ForegroundColor Yellow
    $array += $OUTGPO
}

$array | Sort-Object name | Out-Gridview -Title "Group Policies" -OutputMode Multiple
