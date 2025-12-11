Function Set-NTFSPermission {
    <#
    .SYNOPSIS
        Adds NTFS permissions to a folder with inheritance enabled.
    .EXAMPLE
        Set-NTFSPermission -Path "C:\Temp\MyFolder" -Identity "DOMAIN\Group" -AccessRights Modify
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$Identity,

        [Parameter()]
        [ValidateSet('FullControl', 'Modify', 'ReadAndExecute', 'Read', 'Write')]
        [string]$AccessRights = 'FullControl'
    )

    Process {
        if (-not (Test-Path -Path $Path)) {
            Write-Error "Path not found: $Path"
            return
        }

        try {
            $Acl = Get-Acl -Path $Path -ErrorAction Stop

            # ContainerInherit, ObjectInherit = Applies to this folder, subfolders, and files.
            # PropagationFlags.None = Ensure inheritance actually flows down.
            $Permission = $Identity, $AccessRights, 'ContainerInherit, ObjectInherit', 'None', 'Allow'
            $AccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $Permission

            # AddAccessRule will merge this new rule with existing ones
            $Acl.AddAccessRule($AccessRule)
            Set-Acl -Path $Path -AclObject $Acl -ErrorAction Stop
            
            Write-Host "Successfully added '$AccessRights' for '$Identity' on '$Path'" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to set permissions on $Path. Error: $_"
        }
    }
}
