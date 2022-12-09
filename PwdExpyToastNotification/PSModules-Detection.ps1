
$RAUMod = get-module -name RunAsUser -ListAvailable
$MSOmod = get-module -name MSonline -ListAvailable
$AZADMod = get-module -name AzureAD -ListAvailable
if ($MSOmod -and $AZADMod -and $RAUMod) {
    Write-output "Modules exists :)"
    exit 0
} else {
    Write-output "Modules not present :("
    exit 1
}

