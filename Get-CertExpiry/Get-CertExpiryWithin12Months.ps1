Import-Module WebAdministration -ErrorAction SilentlyContinue
#credit: PSwriteword author evotec
Import-Module PSWriteWord -force -ErrorAction SilentlyContinue
Clear-Host
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

$file = $env:COMPUTERNAME
#$file = "$dir\servers.csv" #small test list
$DOCreport = "$dir\Certs expiry 12 months.docx"

$servers = Get-content $file
$otoday = Get-Date -Format "dd/MM/yyy"

# change the addmonths to the period you require e.g. 3, 6 ,9 ,12
$today = ((Get-Date).AddMonths(12)).tostring("dd-MM-yyyy")
write-host "Today is: $otoday"

$newdoc = New-WordDocument $DOCreport -Verbose
#$logoimage = "$dir\Header-Logo.png"
#$footerimage = "$dir\Footer-Logo.png"

#add your header image
#Add-WordPicture -WordDocument $newdoc -ImagePath $logoimage -Alignment right -ImageWidth 170 -ImageHeight 80
Add-WordText -WordDocument $newdoc -Text "Report compiled on $otoday." -Alignment Right -FontSize 08 -FontFamily 'Calibri' -Color lightgray -HeadingType Heading1 
Add-wordtext -WordDocument $newdoc -Text "Certificates" -FontSize 18 -fontfamily 'Bahnschrift Condensed'  -Color Black
add-wordtext -WordDocument $newdoc -Text "The following report details all certificate that will expire before $today, please review and make relevant arrangements to replace, or renew these certificates to reduce the risk of a service outage." -FontSize 12 -fontfamily 'Bahnschrift Light SemiCondensed'

Add-WordParagraph -WordDocument $newdoc
Add-wordtext -WordDocument $newdoc -Text "Certificates Expiring Before $today" -FontSize 18 -fontfamily 'Bahnschrift Condensed' -Color Black

$T = New-wordtable -WordDocument $newdoc -NrColumns 5 -NrRows 1 
Add-WordTableRow -Table $t -Index 1
$expired = @()

foreach ($server in $servers) { #each server start
    Write-host "Processing Certificates on $server" -ForegroundColor Yellow
	$certs = Invoke-Command -ComputerName $server -ScriptBlock { Get-ChildItem -path Cert:\LocalMachine\My -Recurse -erroraction SilentlyContinue | select-Object Subject, Thumbprint, NotBefore, NotAfter -ExcludeProperty PSComputerName, RunspaceId, PSSHowComputerName | Sort-Object Notafter -Descending } -ErrorAction SilentlyContinue
    
    foreach ($c in $certs) { #each cert start
        $subs = $c.subject.split(",")
        foreach ($sub in $subs) {
            if ($sub -like "*CN=*") {
                $sj = $sub -replace 'CN=', ''
                $SJ = $sj -replace '\s',''
                }
        }
        $edate = $c.NotAfter.ToString("dd-MM-yyyy")
        $ts = New-TimeSpan -Start $edate -End $today
        if ($ts.days -gt 0 -and $ts.Days -lt 365) {
            $item = [PSCustomobject]@{
                Name = $server
                subject = $SJ
                Thumbprint = $c.Thumbprint
                Notbefore = $c.notbefore.tostring("dd-MM-yyyy")
                Notafter = $c.NotAfter.tostring("dd-MM-yyyy")
            }
            $expired = $expired + $item
        }
    } #each cert end
} #each server end

$sortexpired = $expired | Sort-Object $expired.notafter
$sortexpired | Format-Table -AutoSize

Add-WordTable -Table $t -DataTable $sortexpired -Design MediumShading1Accent2 -Alignment left -AutoFit Window -FontSize 10, 7 -ContinueFormatting 
Add-wordline -WordDocument $newdoc -LineColor darkgray -LineType single -LineSpace 0.2

#add your footer image
#Add-WordPicture -WordDocument $newdoc -ImagePath $footerimage -Alignment right -ImageWidth 400 -ImageHeight 85

#save the doc file
Save-WordDocument -WordDocument $newdoc #-KillWord

#Send report to someone ;)
<#
$From = "CertCheck@yourdomain.com"
$To = "someone@yourdomain.com"
$Attachment = "$dir\Certs expiry 12 months.docx"
$Subject = "Certs expiring within 12 Months"
$Body = "<h3><u>Certificates expiring within the next 12 Months</u></h3><p>Please find attached the DOCX report detailing certificates that will expire within the next 12 months<BR>Please review the report and make relevant arrangements to replace, or renew these certificates to reduce the risk of a service outage.</p></br/>Your IT Department."
$SMTPServer = "[yoursmtpserver]"
$SMTPPort = "25"
Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $SMTPServer -port $SMTPPort -Attachments $Attachment –DeliveryNotificationOption OnSuccess
#>
