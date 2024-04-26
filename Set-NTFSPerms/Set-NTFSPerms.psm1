Function Set-NTFSPerm($parent, $foldername, $groupname) {
    #can be used to create the folder if it doesn't exist
    #New-item -Path $parent -Name $foldername -ItemType Directory -force -Verbose
    $path = join-path -path $parent -childpath $foldername
    $Acl = Get-Acl $path
    $permission = $groupname, 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    $AR = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
    $Acl.SetAccessRule($Ar)
    Set-Acl $path $Acl
}

#usage
#Set-ntfsperms -parent "c:\temp" -folder "myfolder" -groupname "domain\groupname"
