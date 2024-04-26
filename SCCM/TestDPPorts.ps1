Clear-Host
# Press 'F5' to run this script. Running this script will load the ConfigurationManager
# module for Windows PowerShell and will connect to the site.
#
# This script was auto-generated at '02/04/2024 15:45:42'.

# Site configuration
$SiteCode = "GRP" # Site code e.g. ABC 
$ProviderMachineName = "gaguxbmem01.gag.citrix" # SMS Provider machine name e.g sccm.contoso.com

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if($null -eq (Get-Module ConfigurationManager)) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

#changed this to Dynamic in the Foreach loop
#$dps = @("[FQDN of DP1]", "[FQDN of DP2]")


$ports = @(80, 135, 139, 443, 445, 10123)
#$ports = @(67, 68, 80, 135, 139, 443, 445, 4011, 8530, 8531, 10123) #full range of ports inc pxe ports

#difined array
$results = @()
Write-host "`n`n`n`n`n`n`n`n"

#loop through each DP
foreach ($dp in (Get-CMDistributionPoint | Select-Object -ExpandProperty NetworkOSPath)) {
    $CleanedDPName = $dp -replace "\\", ""
	Write-host "`nProcessing " -NoNewline -ForegroundColor Yellow
    Write-host $CleanedDPName -NoNewline
    Write-host ", please wait..." -ForegroundColor Yellow
    
    foreach ($port in $ports) {
        Write-host "`tTesting Port " -NoNewline -ForegroundColor Cyan
        Write-Host "$port " -nonewline
        
        #test-netconnection is slow and doesn't have a timeout uncomment if you want to use this.
        #$test = Test-NetConnection -ComputerName $dp -port $port -InformationLevel Detailed
        
        #.net command does the same but can have a timeout, set it to 300 ms
        $test = (New-Object System.Net.Sockets.TcpClient).ConnectAsync("$CleanedDPName", "$port").Wait(300)
			
        if ($test -eq "True") {
            Write-host "Succeeded" -ForegroundColor Green
            $output = [PSCustomObject]@{
                DistributionPoint = $CleanedDPName
                Port = $port
                Result = "Successful"
            }
        } else {
            Write-host "Failed" -ForegroundColor RED
            $output = [PSCustomObject]@{
                DistributionPoint = $CleanedDPName
                Port = $port
                Result = "Failed"
            }
        }    
        $results += $output
    }
}

$bad = @()
$good = @()
foreach ($result in $results) {
    if ($($result.result) -eq "Successful") {
        $good += $result
    } else {
        $bad += $result
    }
}

if ($bad.count -gt 0) {
    Write-warning "`nPort Test, Failed, failures listed below :("
    $bad | Format-Table -AutoSize
}else{
    Write-host "Port test completed successfully :)!" -ForegroundColor Green
}
#if you want the GOOD ports, uncomment below
#$good | FT -AutoSize


