$Services = @(
    'Spooler',
    'W32Time'
)

$RestartDelayMs = 60000  # 60 seconds, adjust to taste
$ResetAfterSeconds = 86400  # 24 hours
$ProgramPath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$ProgramParameters = '-executionpolicy bypass -windowstyle hidden -file "C:\Scripts\ServiceMonitoring\Service-monitor.ps1"'

function Set-ServiceRecoveryOptions {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,

        [Parameter(Mandatory)]
        [int]$RestartDelayMs,

        [Parameter(Mandatory)]
        [int]$ResetAfterSeconds,

        [Parameter(Mandatory)]
        [string]$ProgramPath,

        [Parameter(Mandatory)]
        [string]$ProgramParameters
    )

    # Validate service exists
    try {
        $null = Get-Service -Name $ServiceName -ErrorAction Stop
    } catch {
        Write-Warning "Service '$ServiceName' not found. Skipping."
        return
    }

    $actions = "restart/$RestartDelayMs/restart/$RestartDelayMs/run/0"
    $fullRunCommand = "$ProgramPath $ProgramParameters"

    Write-Verbose "Setting failureflag=1 for '$ServiceName'..."
    $ff = sc.exe failureflag "$ServiceName" 1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to set failureflag for service '$ServiceName'. Output: `n$ff"
        return
    }

    Write-Verbose "Configuring failure actions for '$ServiceName'..."
    $fa = sc.exe failure "$ServiceName" reset= $ResetAfterSeconds actions= $actions command= "$fullRunCommand"
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to set failure actions for service '$ServiceName'. Output: `n$fa"
        return
    }

    # (Optional but recommended on newer Windows) ensure the service is allowed to take actions on crashes from non-crash exits:
    # e.g., treat non-crash failure as service failure. Not strictly required; uncomment if desired.
    # sc.exe failureflag "$ServiceName" 1 | Out-Null

    Write-Host "Recovery options applied to '$ServiceName'"

    # Verify
    Write-Verbose "Verifying with 'sc qfailure'..."
    $q = sc.exe qfailure "$ServiceName"
    Write-Host $q
}


$curr = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($curr)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script in an elevated PowerShell session (Run as Administrator)."
    return
}

foreach ($svc in $Services) {
    Set-ServiceRecoveryOptions -ServiceName $svc `
        -RestartDelayMs $RestartDelayMs `
        -ResetAfterSeconds $ResetAfterSeconds `
        -ProgramPath $ProgramPath `
        -ProgramParameters $ProgramParameters `
        -Verbose
}
