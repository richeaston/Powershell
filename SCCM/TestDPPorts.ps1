cls
$dps = @("[FQDN of DP1]", "[FQDN of DP2]")
$ports = @(80, 135, 139, 443, 445, 10123)
#$ports = @(67, 68, 80, 135, 139, 443, 445, 4011, 8530, 8531, 10123) #full range of ports inc pxe ports
$results = @()
Write-host "`n`n`n`n`n`n`n`n"
foreach ($dp in $dps) {
    Write-host "Processiing " -NoNewline -ForegroundColor Yellow
    Write-host $dp -NoNewline
    Write-host ", please wait..." -ForegroundColor Yellow
    foreach ($port in $ports) {
        Write-host "`tTesting Port " -NoNewline -ForegroundColor Cyan
        Write-Host "$port " -nonewline
        $test = tnc -ComputerName $dp -port $port -InformationLevel Detailed
        if ($test.TcpTestSucceeded -eq "False") {
            Write-host "Succeeded :)" -ForegroundColor Green
        } else {
            #Write-host "Failed :)" -ForegroundColor RED
        }    
        $results += $test
    }
}
$bad = @()
$good = @()
foreach ($result in $results) {
    if ($result.TcpTestSucceeded -eq "True") {
        $good += $result
    } else {
        $bad+= $result
    }
}

if ($bad.count -gt 0) {
    Write-warning "`nPort Test, Failed, failures listed below :("
    $bad | FT -AutoSize
}else{
    Write-host "Port test completed successfully :)!" -ForegroundColor Green
}
#if you want the GOOD ports, uncomment below
#$good | FT -AutoSize


