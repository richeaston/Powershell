Function Get-InstalledSoftware {
    <#
    .SYNOPSIS
        Retrieves a list of installed software from the Registry.
    .DESCRIPTION
        Scans HKLM (64-bit), HKLM (32-bit WOW64), and HKCU hives for installed software.
    .PARAMETER Name
        The name (or partial name) of the software to find. Accepts wildcards.
    .EXAMPLE
        Get-InstalledSoftware -Name "Google"
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position=0, ValueFromPipeline=$true)]
        [string]$Name = "*"
    )

    Process {
        # Define all 3 registry locations to ensure we don't miss 32-bit or User-level apps
        $RegistryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",           # 64-bit System
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", # 32-bit System
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"            # Current User
        )

        # Process all paths and output objects immediately
        $Results = foreach ($Path in $RegistryPaths) {
            Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue | 
                Where-Object { 
                    $_.DisplayName -and ($_.DisplayName -like "*$Name*") 
                } | 
                Select-Object @{N='Name';E={$_.DisplayName}}, @{N='Version';E={$_.DisplayVersion}}
        }

        # Sort and remove duplicates (common when scanning multiple hives)
        $Results | Sort-Object Name | Select-Object -Unique Name, Version
    }
}
