Function SetNTFS-Perm($parent, $foldername, $groupname) {
    New-item -Path $parent -Name $foldername -ItemType Directory -force -Verbose
    $path = "$parent\$foldername"
    $Acl = Get-Acl $path
    $permission = $groupname, 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    $AR = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
    $Acl.SetAccessRule($Ar)
    Set-Acl $path $Acl
}
