if (!(test-path "HKCR:\")) {
    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
}

$classpath = "Registry::HKCR:\"
$keyname = "MSPWDToastNotification"
$keyDefault = "url:MSPWDToastNotification"
$keyeditflags = "2162688"
$valcontent = '"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --app=https://aka.ms/sspr'

set-location -path HKCR:\

$classcheck = Get-ChildItem -Path "HKCR:\$($keyname)\" -Recurse -ErrorAction SilentlyContinue
if (!($classcheck)) {
    #create class protocol
    new-item -Path "HKCR:\\" -Name $keyname -ItemType directory -Verbose 
        new-itemproperty -Path "HKCR:\\$keyname" -name "(Default)" -PropertyType "string" -Value $keydefault -Verbose
        new-itemproperty -Path "HKCR:\\$keyname" -name "EditFlags" -PropertyType "DWORD" -Value $keyeditflags -Verbose
        new-itemproperty -Path "HKCR:\\$keyname" -name "URL Protocol" -PropertyType "string" -Value "" -Verbose
    new-item -Path "HKCR:\\$keyname" -Name "Shell" -ItemType directory -Verbose
    new-item -Path "HKCR:\\$keyname\Shell" -Name "Open" -ItemType directory -Verbose
    new-item -Path "HKCR:\\$keyname\Shell\Open" -Name "command" -ItemType directory -Verbose
        new-itemproperty -Path "HKCR:\\$keyname\Shell\Open\command" -name "(Default)" -PropertyType "string" -Value $valcontent -Verbose
}
write-output "Registry Hives Created, Complaint"
exit 0        



