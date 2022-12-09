cls
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$domain = Get-ADDomain | select -ExpandProperty DNSRoot
$logdate = get-date -Format "ddMMyyyy"
$logfile = "$dir\logs\Update-log-$logdate.log"
$excludedservers = "$dir\Excluded-servers.txt"

#check for logfile if none create it
if (!(test-path $logfile)) { new-item -Path "$dir\logs" -name "Update-log-$logdate.log" -force -verbose }
$dt = get-date -Format "HH:mm:ss dd/MM/yyyy"
add-content -Path $logfile -Value "$dt : Logfile Created`n"

if (!(test-path $excludedservers)) {
    new-item -Path $dir -name "Excluded-servers.txt" -force -verbose 
    $dt = get-date -Format "HH:mm:ss dd/MM/yyyy"
    add-content -Path $logfile -Value "$dt : Excluded Servers file not found, created`n"
} else {
    $dt = get-date -Format "HH:mm:ss dd/MM/yyyy"
    add-content -Path $logfile -Value "$dt : Excluded Servers file found, Parsing`n"
    $excluded = get-content $excludedservers
    Write-host "$($excluded.count) excluded servers in list" -ForegroundColor Cyan
}    

#write domain
$dt = get-date -Format "HH:mm:ss dd/MM/yyyy"
add-content -Path $logfile -Value "$dt : Domain = $domain`n"

#get servers
$servers = Get-ADComputer -Filter {OperatingSystem -like "*windows*server*"} -Properties * | select -ExpandProperty Name |  sort-object

$dt = get-date -Format "HH:mm:ss dd/MM/yyyy"
add-content -Path $logfile -Value "$dt : $($servers.count) servers found in $domain domain`n"

write-host "`n"

foreach ($server in $servers) {
    if (Test-connection -ComputerName $server -Count 1 -ErrorAction SilentlyContinue) {
        if ($excluded -contains $server) {
            Write-host "$server Online" -foregroundcolor Green
            Write-host "`t$server in excluded list" -ForegroundColor Gray
            $dt = get-date -Format "HH:mm:ss dd/MM/yyyy"
            add-content -Path $logfile -Value "$dt : $server in excluded list`n"
        } else {
            Write-host "$server Online"  -foregroundcolor Green
            $dt = get-date -Format "HH:mm:ss dd/MM/yyyy"
            add-content -Path $logfile -Value "$dt : $server online`n"
        
            #check for enough freespace on c:
            $rs = Invoke-command -computername $server { get-psdrive C | Select-Object Free -ErrorAction SilentlyContinue } | select PSComputername, Free
            $freegb = [math]::Round($rs.free/1GB,2)
            
            if ($freegb -lt '10') {
                Write-host "`tWarning: insufficuent Space on $($rs.pscomputername) C: $($freegb) GB" -foregroundcolor Magenta
                $dt = get-date -Format "HH:mm:ss dd/MM/yyyy"
                add-content -Path $logfile -Value "$dt Warning: insufficuent Space on $($rs.pscomputername) C:`n"
            } else {
                Write-host "`t$($rs.pscomputername) C DriveSpace: $($freegb) GB" -foregroundcolor Yellow
                $dt = get-date -Format "HH:mm:ss dd/MM/yyyy"
                add-content -Path $logfile -Value "$dt : $($rs.pscomputername) Space: $($freegb) GB`n"
                
                <# uncomment to update the server
                #windows update
                Write-host "`tRunning a Windows Update on $server"
                $dt = get-date -Format "HH:mm:ss dd/MM/yyyy"
                add-content -Path $logfile -Value "$dt : Running a Windows Update on $server`n"
                $modcmd = "Install-Module -Name PSWindowsUpdate -Confirm:$false -force -allowclobber | Import-Module -Force"
                Invoke-command -computername $server { $modcmd }
                Invoke-command -computername $server { Get-WindowsUpdate -AcceptAll -Download -Install -MicrosoftUpdate -Verbose }
                #>
            
             }
        }
    } Else{
        Write-host "$server offline or not responding" -ForegroundColor DarkGray
        $dt = get-date -Format "HH:mm:ss dd/MM/yyyy"
        add-content -Path $logfile -Value "$dt Warning: $server offline or not responding`n"
    }
        
}

$dt = get-date -Format "HH:mm:ss dd/MM/yyyy"
add-content -Path $logfile -Value "$dt Finished processing server list`n"


