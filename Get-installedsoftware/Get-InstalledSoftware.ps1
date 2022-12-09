# Description: script to gather info from endpoint of installed software
# Author: Richard Easton
# Date: 29/09/2021
# Requires Admin: no
# Usage: get-installedSoftware (will list all software)
# Usage: get-installedSoftware -name "Google Chrome" (will list only Google Chrome)



Function Get-installedsoftware ($name) {
    $installed = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -ne $null -and $_.DisplayName -like '*$($name)*'} | select DisplayName, DisplayVersion | sort-object DisplayName
    $sassets = @()
    foreach ($i in $installed) {
        $item = [pscustomobject]@{
            Name = $i.Displayname
            Version = $i.DisplayVersion
        }
        $sassets += $item    
    }
    #detect software installs
    write-output $sassets
}
