cls
$tabcount = 30 
$master = Start-Process "MSedge.exe" "http://www.bing.com/" -passthru
$stubs = @()
for ($a = 0; $a -lt $tabcount; $a++) {
   $RandomWord = (48..57) + (65..90) + (97..122) | Get-Random -Count 1 | % {[char]$_}
   $RandomQuestion = Get-Random -InputObject("What+is+","Definition+of+","Pronunciation+of+","Thesaurus+","Examples+of+","prefixes+for+","suffixes+for+")
   $tab =  start-process "MSEDGE.exe" "http://www.bing.com/search?q=$RandomQuestion$RandomWord", '--profile-directory="Default"' -PassThru | Get-Process | Select ProcessName, ID, StartTime 
   #$tab.Id
   $MSTAB = [PSCustomObject]@{
        SessionNT = $tab.ProcessName
        SessionID = $tab.Id
        SessionST = $tab.StartTime
   }
   $stubs += $MSTAB
}

#foreach ($stub in $stubs) {
#}

$stubs

start-sleep -seconds 30
stop-process -name msedge -Force