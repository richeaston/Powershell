Clear-Host
$vmno = read-host "Enter no of vm's needed"
$i = 0
do {
$vmname = read-host "Enter New VM Name, or ! to quit."
if ($null -ne $vmname -and $vmname -ne "!") {
    $path = ".\VMs\$vmname.vhdx"
    
    if (!(test-path $path)) {
        $vmgen = read-host "VM Generation, e.g. 1 or 2"
        Hyper-V\New-VM -NewVHDPath $path -NewVHDSizeBytes 40gb -Name $vmname -Generation $vmgen -MemoryStartupBytes 4gb -Path .\vmdata -SwitchName "virtual switch"
        $isos = Get-ChildItem -Path "c:\iso\" -Filter "*.iso" | Select-Object -expandproperty PSchildname
        Write-host "Please Select OS "
        $s = 0
        foreach ($iso in $isos) {
            if ($s -eq 0) {
                $OS = read-host "(Y/N) Do you want to install" $iso
                if ($os -eq "y") {
                    Add-VMDvdDrive -vmName $vmname -Path "C:\iso\$iso"
                    Set-VMDvdDrive -VMName $vmname -Path "C:\iso\$iso"
                    $s = 1
                }
            }
        }
        $dvd = Get-VMDvdDrive -VMName $vmname
        Set-VMFirmware -VMName $vmname -FirstBootDevice $dvd 
        Start-VM -Name $vmname
        VMConnect.exe localhost $vmname
        $i++
    } else {
        Write-host "$vmname already exists :(" -ForegroundColor Red
    }
}
}
until ($i -eq $vmno)
