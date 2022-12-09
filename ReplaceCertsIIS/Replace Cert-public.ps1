##################################################
# Script Function: Replace Certs on IIS servers  #
# Author: Rich Easton                            #
# Date: 11/09/2018                               #
# Requires Admin rights: Yes                     #
##################################################

#import IIS modules.
Import-Module WebAdministration;
#set the cert path location.
SET-LOCATION CERT:\LOCALMACHINE\MY 
cls

#define path of new cert, remember to change this if using on servers
$certpath = "[path to your new cert]"
$certname = "[subjectname of old cert]"

#get the cert that matches the $certname
$OFISCert = Get-Childitem | where-object {$_.Subject -like "*$certname*"};

#Remove Current cert
if ($OFISCert) {
    write-host "Old cert exists, removing" -ForegroundColor red
    Get-ChildItem -Path cert:\LocalMachine\My -DnsName $certname | Remove-Item
} else {
    Write-host "Cert not found, processing rest of script`n" -ForegroundColor Gray
}

    #check for cert existance, install if not present
    $OFISCert = Get-Childitem | where-object {$_.Subject -like "*$certname*"};
    #enter password for the new SSL cert
    $certpwd = read-host "Enter PFX password" -AsSecureString 
    Get-ChildItem -Path $certpath | Import-PfxCertificate -CertStoreLocation "CERT:\LOCALMACHINE\MY" -Password $certpwd
    Write-host
    #check the cert has been imported ok
    $OFISCert = Get-Childitem | where-object {$_.Subject -like "*$certname*"};
    write-host "Certname:`t"   $Ofiscert.Subject -ForegroundColor Cyan
    write-host "===========================" -ForegroundColor White
    write-host "Thumbprint:`t" $ofiscert.Thumbprint"`n" -ForegroundColor Yellow
    Dir IIS:\SslBindings\!443!$Ofiscert.Subject;
    
    #get all the websites that are not "Default web site"
    $hostnames = Get-Website -name * | where-object {$_.Name -notlike 'Default Web Site'} | select-object -ExpandProperty Name
    
    #Process each host, and bind the new SSL cert
    Foreach ($hostname in $hostnames) {
        #only get https sitez, ignore http sites
        if ($hostname -ne "[sitetoexclude]"){ 
            $binding = get-webbinding -name $hostname -Protocol "https"
            if ($binding -ne $null) {
                write-host "Sitename:`t" $hostname
                #bind to new cert
                $binding.AddSslCertificate($OfisCert.GetCertHashString(), "my")
                Write-host $Ofiscert.Subject "Set as certificate for" $hostname "`n" -ForegroundColor Green
            }
        }
}

Write-Host "Processed all Websites on $env:COMPUTERNAME"