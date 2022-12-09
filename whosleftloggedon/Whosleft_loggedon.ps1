Clear-Host
$Servers = Get-ADComputer -Filter {OperatingSystem -like "*server*"} | Where-Object {$_.name -notlike '*-AG' -and $_.enabled -eq 'True'} | Select-Object -ExpandProperty name | sort-object
$results = @()
​
Foreach ($ComputerName in $Servers) {
    Write-Host "Querying $ComputerName" -ForegroundColor Yellow
    try {
        $queryResults = (qwinsta.exe /server:$ComputerName 2> $null | ForEach-Object { (($_.trim() -replace "\s+",","))} | ConvertFrom-Csv -ErrorAction SilentlyContinue) 
    }
    Catch {
        Write-Host $_.Exception.Message
    }
      
    ForEach ($queryResult in $queryResults) { 
        if ($($queryResult.USERNAME) -match "[a-z]") {
            $Hash = @{
                ComputerName = $ComputerName
                UserName     = $($queryResult.USERNAME)
                SessionId    = $($queryResult.SESSIONNAME -replace 'rdp-tcp#','')
            }
        
            # Check the session state
            switch ($queryResult.username) {
                # If UserName is a number, it's an unused session
                {$_ -match "[0-9]"} {
                    $Hash.Add("SessionState","InActive")
                    break
                }
                {$_ -match "[a-zA-Z]"} {
                    $Hash.Add("SessionState","Active")
                    break
                }
                default {
                    $Hash.Add("SessionState","Unknown")
                }
            }
            
            Write-host "`tUsername: " -NoNewline -ForegroundColor white
            Write-host $Hash.username -NoNewline -ForegroundColor cyan
            Write-host " Session Detected on " -NoNewline -ForegroundColor white
            Write-host $hash.ComputerName -ForegroundColor Cyan
            
            $newr = New-Object -TypeName PSObject -Property $Hash
            $results = $results + $newr
        
        }
    }
​
    
}
$results | sort-object | Out-gridview -Title "Logged on users" -PassThru | Clip
