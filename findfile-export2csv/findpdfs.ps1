$array = @()

$files = Get-ChildItem -Filter "*.pdf" -Path C: -Recurse | Select-Object Name, Fullname, Lastaccesstime

foreach ($file in $files) {
    $acl = get-acl $file.fullname | Select-Object -ExpandProperty Owner
    
    $output = [PScustomobject]@{
        acl = $acl
        name = $file.Name
        path = $file.FullName
        lastaccessed = $file.LastAccessTime
    }
    $array += $output
}

$array | Sort-object Name

$array | Export-Csv "D:\pdfs.csv" -force -NoClobber -NoTypeInformation
