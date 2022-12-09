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
if ($classcheck) {
    Write-output "Registry hives exist, compliant"
    Remove-PSDrive -Name HKCR -Force  
    exit 0
} else {
    Write-output "Registry hives do not exist!"
    exit 1
}
