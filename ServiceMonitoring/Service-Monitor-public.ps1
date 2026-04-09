# REPLACE WITH YOUR ACTUAL WEBHOOK URL
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$WebhookUrl = "[teams webhook here]"
$services = @("AxInstSV") # Add more services here if needed
$jsonPath = Join-Path -Path $PSScriptRoot -ChildPath "adaptive_card.json"

if (-not (Test-Path $jsonPath)) {
    Write-Error "Could not find adaptive_card.json at $jsonPath. Please ensure the JSON file is in the same folder as this script."
    exit
}

$jsonTemplate = Get-Content -Path $jsonPath -Raw

foreach ($serviceName in $services) {
    Write-Host "Checking $serviceName..." -NoNewline
    
    $currentStatus = Get-Service -Name $serviceName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status
    
    if ($currentStatus -eq "Stopped") {
        Write-Host " STOPPED. Sending Alert." -ForegroundColor Red

        $serverName = $env:COMPUTERNAME
        
        $cardJson = $jsonTemplate -replace '\$\{serverName\}', $serverName
        $cardJson = $cardJson -replace '\$\{service\}', $serviceName
        $cardJson = $cardJson -replace '\$\{state\}', "Stopped"

        try {
            Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $cardJson -ContentType 'application/json'
            Write-Host "Alert sent successfully for $serviceName." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to send alert. Error: $_"
        }
    }
    else {
        Write-Host " OK, ($currentStatus)." -ForegroundColor Gray
    }
}