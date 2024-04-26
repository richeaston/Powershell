Clear-Host
$domain = Get-ADDomain | Select-Object -ExpandProperty DistinguishedName
$Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
$Searcher.SearchRoot = "LDAP://$domain"
$Searcher.SearchScope = "subtree"
$Searcher.Filter = "(objectClass=organizationalUnit)"
$Searcher.PropertiesToLoad.Add('Distinguishedname') | Out-Null
$LDAP_OUs = $Searcher.FindAll()
$OUs = $LDAP_OUs.properties.distinguishedname
$array = @()
$gpos = $OUs | ForEach-Object { (Get-GPInheritance -Target $_ -ErrorAction SilentlyContinue).GPOlinks } | Select-Object DisplayName, Enabled, Target, status

foreach ($gpo in $gpos) {
    try {
    Write-host "Processing $($GPO.DisplayName)"
    $Comment = Get-GPO -Name $gpo.displayname -ErrorAction SilentlyContinue | Select-Object  Description, gpostatus, owner
    $OUTGPO = [PSCustomObject] @{
        Name = $gpo.DisplayName
        LinkEnabled = $GPO.Enabled
        #Description = $comment.description
        TargetOU = $gpo.Target
        GPOStatus = $comment.gpostatus
        Owner = $comment.owner
        Domain = $domain
    }
        #use this script block to only show disabled or unlinked gpo's
        if ($($outgpo.TargetOU) -eq "" -or $($outgpo.LinkEnabled) -eq $false) {
            $array += $OUTGPO
        }
        
        #use this scriptblock to show all gpo's
        #$array += $OUTGPO
        
    }
    catch {
        Write-Warning "An error occurred getting $($GPO.DisplayName) data!"
    }
    
}
#$array | Sort-Object Name | Export-Csv -Path C:\export_GPOs.csv -NoTypeInformation -NoClobber
$array | Sort-Object Name | Out-GridView -Title "Group Policy Report for $domain" -OutputMode Multiple
#$array
