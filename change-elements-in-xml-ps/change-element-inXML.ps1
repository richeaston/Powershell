Clear-Host
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$file = "$dir\myXML.xml"
$newfile = "$dir\myXML-new.xml"

#read in the json
[xml]$xml = get-content -Path $file
foreach ($element in $xml.NewDataSet)
{
    $element.myelement = "xxxxxxxxxxx"
}
foreach ($element in $xml.NewDataSet.mysubnode)
{
    $element.element1 = "xxxxxxxxxxx"
    $element.element2 = "xxxxxxxxxxx"
    $element.element3 = "xxxxxxxxxxx"
}

# Then you can save that back to the xml file
$xml.Save($newfile)
