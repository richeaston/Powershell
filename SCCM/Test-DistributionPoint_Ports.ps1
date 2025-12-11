#Requires -Version 5.1
#Requires -Modules ConfigurationManager

<#
.SYNOPSIS
    Tests network connectivity to SCCM Distribution Points.
.DESCRIPTION
    Loads the SCCM module, retrieves all DPs, checks if they are also MPs, 
    and tests the relevant ports (HTTP, HTTPS, SMB, SCCM Notification).
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$SiteCode,

    [Parameter(Mandatory=$true)]
    [string]$ProviderMachineName,

    [int]$TimeoutMilliseconds = 300
)

# --- Initialization ---
Clear-Host
$ErrorActionPreference = "Stop"

# Load Configuration Manager Module safely
if (-not (Get-Module -Name ConfigurationManager)) {
    $AdminUIPath = $ENV:SMS_ADMIN_UI_PATH
    if ($null -eq $AdminUIPath) {
        Throw "SMS_ADMIN_UI_PATH environment variable not found. Is the SCCM Console installed?"
    }
    Import-Module "$AdminUIPath\..\ConfigurationManager.psd1" -Force
}

# Connect to Site Drive
if (-not (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    Write-Host "Connecting to site $SiteCode..." -ForegroundColor Cyan
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName | Out-Null
}
Set-Location "$($SiteCode):\"

# --- Data Gathering ---
Write-Host "Gathering Site Roles..." -ForegroundColor Cyan

# Get all DPs
$DistributionPoints = Get-CMDistributionPoint | Select-Object -ExpandProperty NetworkOSPath
# Get all MPs (network paths) and store in a HashSet for instant lookup
$ManagementPoints   = Get-CMManagementPoint | Select-Object -ExpandProperty NetworkOSPath
$MPSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$ManagementPoints, [System.StringComparer]::OrdinalIgnoreCase)

# --- Main Processing ---
$Results = foreach ($rawDPPath in $DistributionPoints) {
    $ComputerName = $rawDPPath -replace "\\", ""
    
    Write-Host "Processing: $ComputerName" -ForegroundColor Yellow

    # Determine Ports based on Roles
    if ($MPSet.Contains($rawDPPath)) {
        # DP is also an MP: Add port 10123 (Notification Server)
        $Ports = @(80, 135, 139, 443, 445, 10123)
    } else {
        # Standard DP ports
        $Ports = @(80, 135, 139, 443, 445)
    }

    # Test Ports Loop
    foreach ($Port in $Ports) {
        $Status = "Failed"
        
        # --- Optimized Socket Test ---
        try {
            $TcpClient = New-Object System.Net.Sockets.TcpClient
            $ConnectTask = $TcpClient.ConnectAsync($ComputerName, $Port)
            $Signaled = $ConnectTask.Wait($TimeoutMilliseconds)
            
            if ($Signaled -and $TcpClient.Connected) {
                $Status = "Successful"
                Write-Host "    Port $Port : OK" -ForegroundColor Green
            } else {
                Write-Host "    Port $Port : FAIL" -ForegroundColor Red
            }
        }
        catch {
             Write-Host "    Port $Port : ERROR ($($_.Exception.Message))" -ForegroundColor Red
        }
        finally {
            # CRITICAL: Always close the socket to prevent resource exhaustion
            if ($TcpClient) { $TcpClient.Dispose() }
        }

        # Output Object
        [PSCustomObject]@{
            DistributionPoint = $ComputerName
            Port              = $Port
            Result            = $Status
            Role              = if ($MPSet.Contains($rawDPPath)) { "DP + MP" } else { "DP" }
        }
    }
}

# --- Reporting ---
Write-Host "`n--- Summary ---`n"

$FailedChecks = $Results | Where-Object { $_.Result -ne "Successful" }

if ($FailedChecks) {
    Write-Warning "Connectivity issues detected on $($FailedChecks.Count) checks:"
    $FailedChecks | Format-Table -AutoSize
} else {
    Write-Host "All port checks completed successfully!" -ForegroundColor Green
}

# Optional: Return data if used in a larger automation pipeline
# return $Results
