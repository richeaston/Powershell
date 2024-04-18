#This script requires the PSWriteWord Module to run, this can be installed by 
#credit: PSwriteword module Evotec
#install-Module -name PSWriteWord


#import modules
Import-Module PSWriteWord -force
Clear-Host
#Declare variable
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$today = Get-Date -Format "dd-MM-yyy"
​
$array = @()
$SAarray = @()
$docreport = "$dir\HPA-list-$today.docx"
$pdfreport = "$dir\HPA-list-$today.pdf"
$HPAGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins","Administrators")
​
$newdoc = New-WordDocument $DOCreport -Verbose
$logoimage = "$dir\yourlogo.png"
$footerimage = "$dir\yourfooter.png"
$strDomainDNS = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
​
Add-WordPicture -WordDocument $newdoc -ImagePath $logoimage -Alignment right -ImageWidth 170 -ImageHeight 80
Add-WordText -WordDocument $newdoc -Text "Report compiled on $today." -Alignment Right -FontSize 08 -FontFamily 'Calibri' -Color lightgray -HeadingType Heading1 
Add-wordtext -WordDocument $newdoc -Text "HPA Accounts for $strDomainDNS Domain" -FontSize 18 -fontfamily 'Bahnschrift Condensed'  -Color Black
add-wordtext -WordDocument $newdoc -Text "The following report details all HPA accounts on the $strDomainDNS, please review this report to highlight any changes from the previous report." -FontSize 12 -fontfamily 'Bahnschrift Light SemiCondensed'
​
​
​
Foreach ($HPAGroup in $HPAGroups) {
    $array = @()
    $members = Get-ADGroupMember -Identity $HPAGroup | Select-Object Name, SamAccountName
    
    
    foreach ($member in $members) {
        $thislist = [pscustomobject] @{
            #Groupname = $HPAGroup
            Name = $member.Name
            Account = $member.SamAccountName
        }
        $array += $thislist
    }
    $array | Sort-object Name
    Add-WordParagraph -WordDocument $newdoc
    $title = "$HPAGroup ("+$array.count+")"
    Add-wordtext -WordDocument $newdoc -Text $title -FontSize 18 -fontfamily 'Bahnschrift Condensed' -Color Black
    $T = New-wordtable -WordDocument $newdoc -NrColumns 2 -NrRows 1 
    Add-WordTableRow -Table $t -Index 1
    Add-WordTable -Table $t -DataTable $array -Design MediumShading1Accent2 -Alignment left -AutoFit Window -FontSize 10, 7 -ContinueFormatting 
    Add-wordline -WordDocument $newdoc -LineColor darkgray -LineType single -LineSpace 0.2
​
}
​
​
$users = Get-aduser -filter * -searchbase "Ou=ServiceAccounts,DC=yourdomain,DC=local" -Properties * | Where-Object {$_.objectclass -eq 'user'} | Select-Object Name, SamAccountName
​
foreach ($user in $users) {
    $serviceaccts = [pscustomobject] @{
        #Groupname = "Service Account"
        Name = $user.name
        Account = $user.SamAccountName
    }
    $SAarray += $serviceaccts
​
}
​
$SAarray | sort-object Name
Add-WordParagraph -WordDocument $newdoc
$title = "Service Accounts ("+$SAarray.count+")"
Add-wordtext -WordDocument $newdoc -Text $title -FontSize 18 -fontfamily 'Bahnschrift Condensed' -Color Black
$SA = New-wordtable -WordDocument $newdoc -NrColumns 2 -NrRows 1
Add-WordTable -Table $SA -DataTable $SAarray -Design MediumShading1Accent2 -Alignment left -AutoFit Window -FontSize 10, 7 -ContinueFormatting 
Add-wordline -WordDocument $newdoc -LineColor darkgray -LineType single -LineSpace 0.2
Add-WordParagraph -WordDocument $newdoc
Add-WordPicture -WordDocument $newdoc -ImagePath $footerimage -Alignment right -ImageWidth 400 -ImageHeight 85
​
​
#save doc and convert it to a PDF
Save-WordDocument -WordDocument $newdoc -KillWord
$word = new-object -ComObject "word.application"
$doc = $word.documents.open($docreport)
$doc.SaveAs([ref] $PDFreport, [ref] 17)
$doc.Close()
$word.Quit()
​
Remove-item -Path $DOCreport -Force
​
​
