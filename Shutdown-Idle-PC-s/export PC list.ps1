$basepath = "c:\\shutdown"
$file = "$basepath\clist.txt"
Get-ADComputer -Filter * -SearchBase "OU=[pc'sOU],DC=domain,DC=org" -Properties *  | Select-Object -Property Name | Sort-Object -Property name, ws | Out-File $file 
[System.Windows.MessageBox]::Show("PC list exported to $file")
