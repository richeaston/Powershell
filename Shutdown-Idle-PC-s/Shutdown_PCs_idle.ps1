#Script Function: shutdown pc's with noone logged in.
#Written by Richard Easton 

#set Active Directory Base search area.
#replace anyhting in [] with your information.
$ousearchbase = "OU=[yourPC'sOU],DC=[domain],DC=org"

#Set domain admin credentials (get-credentials prompts of password input)
#$username / $Password sends them to the PS script, use this for scheduled tasks

#base paths
$basepath = "c:\shutdown"
$logpath = "$basepath\logs"
#replace anything in [] with your information.
$username = "domain\[dadmin account]"
#replace anything in [] with your information.
$password = convertto-securestring "[password]" -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

#location of files.
$file = "$basepath\clist.txt"

#test if the logs directory exists
if (test-path -path $logpath) {
} else {
new-item $logpath -type directory
}

#get date to generate log filename
$cd = get-date -format D
$log = "c:\shutdown\logs\$cd.log"
#create log filename
new-item $log -type file

#delete the file if it exists.
if (Test-Path -Path $file) {
Remove-Item($File)
}

#generate the list of PC from the AD.
Get-ADComputer -Filter * -SearchBase $ousearchbase -properties Name | Select-Object name | Sort-Object name | Out-File -FilePath $file -NoClobber

#Remove any blank lines from the file.
(Get-Content $file) | Where-Object {$_.trim() -ne "" } | set-content $file
$content = Get-Content($file)

#get start time.
get-date -DisplayHint Time
$start = "$ft Shutdown Task Started"

out-file -FilePath $log -append -Encoding string -InputObject $start -NoClobber

#read through the list for each pc name and run the stop-computer cmdlet (will shutdown any computer that doesn't have anyone logged in.
foreach ($name in $null -ne $content) {
if ($name.Trim() -eq "name") {
} elseif ($name.Trim() -eq "----" ) {
} Else {
#stop the $name of the computer.
$pc = $name.Trim()
Stop-Computer -ComputerName $pc -asjob -ErrorAction SilentlyContinue -Authentication Default -Credential $cred -whatif
write-host $pc
$ct = Get-Date -DisplayHint DateTime
$result = "$ct $pc Stop-Computer sent"
out-file -FilePath $log -Append -Encoding string -InputObject $result -NoClobber
}
}

#get finish time
$ft = get-date -DisplayHint Time
$finish = "$ft Shutdown Task completed"
out-file -FilePath $log -append -Encoding string -InputObject $finish -NoClobber
