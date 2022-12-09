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
    $Comment = Get-GPO -Name $gpo.displayname -ErrorAction SilentlyContinue | Select-Object  Description, gpostatus, owner
    $OUTGPO = [PSCustomObject] @{
        'Name' = $gpo.DisplayName
        'Enabled' = $GPO.Enabled
        'Description' = $comment.description
        'Target' = $gpo.Target
        'status' = $comment.gpostatus
        'owner' = $comment.owner
        'domain' = $domain
    }
    $array += $OUTGPO
    }
    catch {
        Write-Warning "An error occurred getting GPO data!"
    }
    
}
#$array | Sort-Object Name | Export-Csv -Path C:\export_GPOs.csv -NoTypeInformation -NoClobber
$array | Sort-Object Name | Out-GridView -Title "Group Policy Report for $domain" -OutputMode Multiple
#$array
