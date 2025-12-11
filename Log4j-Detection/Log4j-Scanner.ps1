<#
.SYNOPSIS
    Log4j / JndiLookup Scanner
.DESCRIPTION
    Scans remote servers for .jar files containing the vulnerable JndiLookup.class.
    Uses Parallel processing and .NET Zip inspection for speed and accuracy.
#>

# --- Configuration ---
$LogPath     = "$PSScriptRoot\logs"
$ServerList  = "$PSScriptRoot\Servers.csv" # Ensure this file exists (one server per line, or CSV with 'Name' header)
$LogDate     = Get-Date -Format "dd-MM-yyyy"
$LogFile     = "$LogPath\ScanLog-$LogDate.log"

# --- Init ---
Clear-Host
if (!(Test-Path $LogPath)) { New-Item -Path $LogPath -ItemType Directory -Force | Out-Null }

# --- Logging Function ---
function Write-Log {
    param (
        [Parameter(Mandatory=$true)] [string]$Message,
        [string]$Color = "White",
        [switch]$NoConsole
    )
    $TimeStamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
    $LogLine   = "$TimeStamp : $Message"
    Add-Content -Path $LogFile -Value $LogLine -ErrorAction SilentlyContinue
    
    if (-not $NoConsole) {
        Write-Host $Message -ForegroundColor $Color
    }
}

# --- Import Servers ---
Write-Log -Message "Starting Script..." -Color Cyan

if (Test-Path $ServerList) {
    # Handles both simple text lists and CSVs with a 'Name' header
    $InputData = Import-Csv $ServerList -Header "TempName" | Select-Object -ExpandProperty TempName
    # Clean up input (remove headers if they exist, trim spaces)
    $Servers = $InputData | Where-Object { $_ -ne "Name" -and $_ -ne "" } | ForEach-Object { $_.Trim() }
    Write-Log -Message "Loaded $($Servers.Count) servers from list." -Color Green
} else {
    Write-Log -Message "Error: Servers.csv not found at $ServerList" -Color Red
    Break
}

# --- The Scan Logic (ScriptBlock) ---
$ScanBlock = {
    # Load .NET Assembly for Zip handling
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    $Findings = @()
    $Drives = Get-PSDrive -PSProvider FileSystem
    
    foreach ($Drive in $Drives) {
        # Get all JAR files (Ignoring errors to prevent access denied stops)
        $Jars = Get-ChildItem -Path $Drive.Root -Include *.jar -Recurse -ErrorAction SilentlyContinue
        
        foreach ($Jar in $Jars) {
            try {
                # Open JAR as ZIP to check contents cleanly
                $Zip = [System.IO.Compression.ZipFile]::OpenRead($Jar.FullName)
                
                # Look for the vulnerable class file
                $VulnerableFile = $Zip.Entries | Where-Object { $_.FullName -like "*JndiLookup.class" }
                
                if ($VulnerableFile) {
                    # Check filename version for mitigation context (User request)
                    $Status = "VULNERABLE"
                    if ($Jar.Name -match "log4j-core-2.1[6-9]" -or $Jar.Name -match "log4j-core-2.[2-9]") {
                        $Status = "Patched/Safe Version"
                    }

                    $Findings += [PSCustomObject]@{
                        Server   = $env:COMPUTERNAME
                        Status   = $Status
                        FileName = $Jar.Name
                        Path     = $Jar.FullName
                        ClassFound = $VulnerableFile.FullName
                    }
                }
                $Zip.Dispose()
            }
            catch {
                # Handle locked files or corrupt zips
                $Findings += [PSCustomObject]@{
                    Server   = $env:COMPUTERNAME
                    Status   = "Error Scanning File"
                    FileName = $Jar.Name
                    Path     = $Jar.FullName
                    ClassFound = $_.Exception.Message
                }
            }
        }
    }
    return $Findings
}

# --- Execution ---
Write-Log -Message "Starting parallel scan. This may take time..." -Color Yellow

# Run against all servers simultaneously
# Note: Using -ErrorAction SilentlyContinue on Invoke-Command to handle offline servers gracefully
$Results = Invoke-Command -ComputerName $Servers -ScriptBlock $ScanBlock -ErrorAction SilentlyContinue

# --- Process Results ---
if ($Results) {
    foreach ($Res in $Results) {
        if ($Res.Status -eq "VULNERABLE") {
            Write-Log -Message "CRITICAL: Found $($Res.FileName) on $($Res.Server) at $($Res.Path)" -Color Magenta
        }
        elseif ($Res.Status -eq "Patched/Safe Version") {
            Write-Log -Message "INFO: Found patched version $($Res.FileName) on $($Res.Server)" -Color Cyan
        }
        elseif ($Res.Status -eq "Error Scanning File") {
            Write-Log -Message "WARN: Could not open $($Res.FileName) on $($Res.Server)" -Color DarkGray
        }
    }
    
    # Optional: Export detailed results to CSV
    $ReportFile = "$LogPath\ScanResults-$LogDate.csv"
    $Results | Select-Object Server, Status, FileName, Path, ClassFound | Export-Csv -Path $ReportFile -NoTypeInformation
    Write-Log -Message "Detailed report saved to: $ReportFile" -Color Green
}
else {
    Write-Log -Message "Scan complete. No vulnerabilities found or servers were unreachable." -Color Green
}

Write-Log -Message "Script Finished."
