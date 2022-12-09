Clear-Host

for ($a = 0; $a -lt 90; $a++) {
   $RandomWord = (48..57) + (65..90) + (97..122) | Get-Random -Count 1 | ForEach-Object {[char]$_}
   $RandomQuestion = Get-Random -InputObject("What+is+","Definition+of+","Pronunciation+of+","Thesaurus+","Examples+of+","prefixes+for+","suffixes+for+")
   Start-Process "microsoft-edge:http://www.bing.com/search?q=$RandomQuestion$RandomWord"  -WindowStyle Minimized
   start-sleep -Milliseconds 1000
   $CP = Get-Process -Name MicrosoftEdgeCP | Select-Object -ExpandProperty Processname
   Stop-Process -Name MicrosoftEdgeCP -Force -PassThru
}

$CP = Get-Process -Name MicrosoftEdgeCP | Select-Object -ExpandProperty Processname
$sh = Get-Process -Name MicrosoftEdgeSH | Select-Object -ExpandProperty Processname

while ($cp.count -gt 0) {
    Stop-Process -Name MicrosoftEdgeCP -Force -PassThru
    Start-Sleep -Milliseconds 200
    $CP = Get-Process -Name MicrosoftEdgeCP -ErrorAction SilentlyContinue | Select-Object Processname
}


while ($sh.count -gt 0) {
    Stop-Process -Name MicrosoftEdgeSH -Force -PassThru
    Start-Sleep -Milliseconds 200
    $sh = Get-Process -Name MicrosoftEdgeSH  -ErrorAction SilentlyContinue | Select-Object Processname
}

Stop-process -name  MicrosoftEdge -Force -PassThru
