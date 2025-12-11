#Requires -Modules ActiveDirectory, PSWriteWord

Import-Module PSWriteWord -Force -ErrorAction SilentlyContinue
Import-Module ActiveDirectory -ErrorAction Stop

Clear-Host

# --- Configuration ---
$scriptpath   = $MyInvocation.MyCommand.Path
$dir          = Split-Path $scriptpath
$today        = Get-Date -Format "dd-MM-yyyy"

# Paths
$DOCreport    = "$dir\HPA-list-$today.docx"
$PDFreport    = "$dir\HPA-list-$today.pdf"
$logoimage    = "$dir\yourlogo.png"
$footerimage  = "$dir\yourfooter.png"

# Active Directory Settings
$HPAGroups    = @("Domain Admins", "Enterprise Admins", "Schema Admins", "Administrators")
# UPDATE THIS PATH
$ServiceAcctOU = "Ou=ServiceAccounts,DC=yourdomain,DC=local" 

# Get Current Domain Name safely
try {
    $strDomainDNS = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
} catch {
    $strDomainDNS = $env:USERDNSDOMAIN
}

# --- Document Initialization ---
Write-Host "Initializing Word Document..." -ForegroundColor Cyan
$newdoc = New-WordDocument $DOCreport

# Header Logo (Check if exists first)
if (Test-Path $logoimage) {
    Add-WordPicture -WordDocument $newdoc -ImagePath $logoimage -Alignment right -ImageWidth 170 -ImageHeight 80
}

# Header Text
Add-WordText -WordDocument $newdoc -Text "Report compiled on $today." -Alignment Right -FontSize 8 -FontFamily 'Calibri' -Color lightgray -HeadingType Heading1 
Add-WordText -WordDocument $newdoc -Text "HPA Accounts for $strDomainDNS Domain" -FontSize 18 -FontFamily 'Bahnschrift Condensed'  -Color Black
Add-WordText -WordDocument $newdoc -Text "The following report details all HPA accounts on $strDomainDNS. Please review this report to highlight any changes from the previous report." -FontSize 12 -FontFamily 'Bahnschrift Light SemiCondensed'

# --- HPA Groups Processing ---
foreach ($HPAGroup in $HPAGroups) {
    Write-Host "Processing Group: $HPAGroup" -ForegroundColor Yellow
    
    # Try/Catch for AD groups in case one doesn't exist
    try {
        # Get members and sort immediately. No intermediate array loop needed.
        $GroupMembers = Get-ADGroupMember -Identity $HPAGroup -Recursive | 
                        Select-Object @{N='Name';E={$_.Name}}, @{N='Account';E={$_.SamAccountName}} |
                        Sort-Object Name
        
        if ($GroupMembers) {
            Add-WordParagraph -WordDocument $newdoc
            $title = "$HPAGroup ($($GroupMembers.Count))"
            Add-WordText -WordDocument $newdoc -Text $title -FontSize 18 -FontFamily 'Bahnschrift Condensed' -Color Black
            
            # Add table directly using the object list
            Add-WordTable -WordDocument $newdoc -DataTable $GroupMembers -Design MediumShading1Accent2 -Alignment Left -AutoFit Window -FontSize 10
            Add-WordLine -WordDocument $newdoc -LineColor darkgray -LineType Single -LineSpace 0.2
        }
    }
    catch {
        Write-Warning "Could not find or process group: $HPAGroup"
    }
}

# --- Service Accounts Processing ---
Write-Host "Processing Service Accounts..." -ForegroundColor Yellow
try {
    # Optimized AD Query: Removed -Properties * and unnecessary Where-Object
    $ServiceUsers = Get-ADUser -Filter * -SearchBase $ServiceAcctOU | 
                    Select-Object @{N='Name';E={$_.Name}}, @{N='Account';E={$_.SamAccountName}} |
                    Sort-Object Name

    if ($ServiceUsers) {
        Add-WordParagraph -WordDocument $newdoc
        $title = "Service Accounts ($($ServiceUsers.Count))"
        Add-WordText -WordDocument $newdoc -Text $title -FontSize 18 -FontFamily 'Bahnschrift Condensed' -Color Black
        
        Add-WordTable -WordDocument $newdoc -DataTable $ServiceUsers -Design MediumShading1Accent2 -Alignment Left -AutoFit Window -FontSize 10
        Add-WordLine -WordDocument $newdoc -LineColor darkgray -LineType Single -LineSpace 0.2
    }
}
catch {
    Write-Warning "Could not process Service Accounts. Check the OU path: $ServiceAcctOU"
}

# Footer Image
if (Test-Path $footerimage) {
    Add-WordParagraph -WordDocument $newdoc
    Add-WordPicture -WordDocument $newdoc -ImagePath $footerimage -Alignment right -ImageWidth 400 -ImageHeight 85
}

# --- Save and Convert to PDF ---
Write-Host "Saving DOCX..." -ForegroundColor Green
Save-WordDocument -WordDocument $newdoc -KillWord

Write-Host "Converting to PDF..." -ForegroundColor Green
$word = New-Object -ComObject "Word.Application"
$word.Visible = $false
$word.DisplayAlerts = [Microsoft.Office.Interop.Word.WdAlertLevel]::wdAlertsNone

try {
    $doc = $word.Documents.Open($DOCreport)
    # 17 is the Enum for wdFormatPDF
    $doc.SaveAs([ref]$PDFreport, [ref]17)
    $doc.Close([ref]$false)
    Write-Host "PDF Saved to: $PDFreport" -ForegroundColor Green
    
    # Cleanup DOCX only if conversion succeeded
    Remove-Item -Path $DOCreport -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Error "Failed to convert to PDF. The DOCX version has been kept. Error: $_"
}
finally {
    # Ensure Word process always quits
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
