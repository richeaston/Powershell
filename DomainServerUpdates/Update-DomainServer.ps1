<#
.SYNOPSIS
    Server Health Check and Update Wrapper
.DESCRIPTION
    Checks AD for Servers, filters exclusions, checks connectivity, 
    checks Disk Space, and prepares for Windows Updates.
#>

# --- Configuration ---
$LogPath        = "$PSScriptRoot\logs"
$ExcludedFile   = "$PSScriptRoot\Excluded-servers.txt"
$MinFreeSpaceGB = 10
$LogDate        = Get-Date -Format "ddMMyyyy"
$LogFile        = "$LogPath\Update-log-$LogDate.log"

# --- Helper Function: Logging ---
function Write-Log {
    param (
        [Parameter(Mandatory=$true)] [string]$Message,
        [string]$Color = "White",
        [switch]$NoConsole
    )
    $TimeStamp = Get-Date -Format "HH:mm:ss dd/MM/yyyy"
    $LogLine   = "$TimeStamp : $Message"

    # Write to file
    Add-Content -Path $LogFile -Value $LogLine -ErrorAction SilentlyContinue

    # Write to console (optional)
    if (-not $NoConsole) {
        Write-Host $Message -ForegroundColor $Color
    }
}

# --- Initialization ---
Clear-Host

# Ensure Log Directory Exists
if (!(Test-Path $LogPath)) { 
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null 
}
# Create Log File
if (!(Test-Path $LogFile)) { 
    New-Item -Path $LogFile -ItemType File -Force | Out-Null 
    Write-Log -Message "Logfile Created" -Color Cyan
}

# Check/Create Exclusion File
$ExcludedList = @()
if (Test-Path $ExcludedFile) {
    $ExcludedList = Get-Content $ExcludedFile
    Write-Log -Message "Excluded Servers file found. $($ExcludedList.Count) servers excluded." -Color Cyan
} else {
    New-Item -Path $ExcludedFile -ItemType File -Force | Out-Null
    Write-Log -Message "Excluded Servers file not found, created empty file." -Color Yellow
}

# --- Main Logic ---

# 1. Get Domain Info
try {
    $Domain = (Get-ADDomain).DNSRoot
    Write-Log -Message "Domain detected: $Domain" -Color Green
}
catch {
    Write-Log -Message "Error: Unable to contact Active Directory. Ensure RSAT is installed." -Color Red
    Break
}

# 2. Get Servers (Optimized Query)
Write-Log -Message "Querying Active Directory for Windows Servers..." -Color Cyan
$AllServers = Get-ADComputer -Filter {OperatingSystem -like "*windows*server*"} | Select-Object -ExpandProperty Name | Sort-Object

# 3. Filter Exclusions
$TargetServers = $AllServers | Where-Object { $_ -notin $ExcludedList }
$SkippedCount  = ($AllServers.Count - $TargetServers.Count)

Write-Log -Message "Found $($AllServers.Count) total servers. Processing $($TargetServers.Count). ($SkippedCount excluded)" -Color Cyan

# 4. Check Connectivity (Parallel)
Write-Log -Message "Checking connectivity..." -Color Cyan
$OnlineServers = @()
$OfflineServers = @()

# Test-Connection in parallel usually requires WMI/ICMP. 
# A quick way to do this in bulk is actually using Test-Connection with -ComputerName taking an array (PS5.1+)
$TestResults = Test-Connection -ComputerName $TargetServers -Count 1 -ErrorAction SilentlyContinue -AsJob | Receive-Job -Wait

foreach ($Server in $TargetServers) {
    if ($TestResults | Where-Object { $_.Address -eq $Server -and $_.StatusCode -eq 0 }) {
        $OnlineServers += $Server
    } else {
        $OfflineServers += $Server
        Write-Log -Message "$Server is OFFLINE or blocking ICMP" -Color DarkGray
    }
}

# 5. Check Disk Space & Updates (Parallel Execution using Invoke-Command)
if ($OnlineServers.Count -gt 0) {
    Write-Log -Message "Scanning $($OnlineServers.Count) online servers for disk space..." -Color Green
    
    # Run the check on all servers simultaneously
    $Results = Invoke-Command -ComputerName $OnlineServers -ErrorAction SilentlyContinue -ScriptBlock {
        $SystemDrive = Get-PSDrive C | Select-Object Used, Free
        $FreeGB      = [math]::Round($SystemDrive.Free / 1GB, 2)
        
        # Create a custom object to return to the host
        [PSCustomObject]@{
            ServerName = $env:COMPUTERNAME
            FreeGB     = $FreeGB
        }

        # --- UPDATE SECTION (Still Commented, but improved) ---
        <# 
        # Check if module exists, if not try to install (requires internet)
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
        }
        Import-Module PSWindowsUpdate
        Get-WindowsUpdate -AcceptAll -Install -Verbose
        #>
    }

    # 6. Process Results
    foreach ($Res in $Results) {
        if ($Res.FreeGB -lt $MinFreeSpaceGB) {
            Write-Log -Message "WARNING: $($Res.ServerName) has low disk space: $($Res.FreeGB) GB" -Color Magenta
        } else {
            Write-Log -Message "$($Res.ServerName) OK. Free Space: $($Res.FreeGB) GB" -Color Green
        }
    }
}

Write-Log -Message "Finished processing server list." -Color Cyan
