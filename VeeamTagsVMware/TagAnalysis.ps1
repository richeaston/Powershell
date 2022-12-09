#test connection to VC server
if ($error) {
    Connect-VIServer -server [your vCenter server]
    }
$logcount = 0

$date = get-date -Format "dd/MM/yy HH:mm:ss"
#Must have c:\scripts folder on source to run correctly
$replog = "c:\Scripts\DailyChecks.log"
#file test for dailychecks.log
if(!(test-path $replog)){New-Item $replog -ItemType File}
cls

#Add-Content $log "Tag analysis started: $date`n"
Add-Content $replog "Tag analysis started: $date`n"

#get the VMHOSTS
$vmhosts = Get-VMHost | select -ExpandProperty Name
$nobackup = $null

#list each VM on each VMHost, by Name
foreach ($vmhost in $vmhosts) {
    $rpo24 = $null
    $rpo12 = $null
    $rpo4 = $null
    $tagmismatch = $null 
    $tagchanges = $null
    $storageerror = $null
       
    write-host
    write-host "$vmhost" -ForegroundColor Yellow
    write-host "==================" -ForegroundColor White
    $vms = Get-VM -location $vmhost | Select -ExpandProperty Name
    
    foreach ($vm in $vms) { 
        #Check the Storage used, to generate the correct tag   
        $storage = Get-HardDisk -vm $vm | Select -ExpandProperty Filename
        
            if ($storage -like '*Gen-*') {
                $suffix = "_GEN"
            } elseif ($storage -like '*Infra-*') {
                $suffix = "_INFRA"
            } elseif ($storage -like '*dev-*') {
                $suffix = "_DEV"
            } else {
                Write-host "`tUnknown datastore found for $vm" -ForegroundColor Red
                $storageerror = $storageerror + "$vm : Warning Unknown storage location found`n"
                $suffix = ""
            }
       
       $validate = Get-TagAssignment -Entity $vm -cat "Remote Replication" | Select -ExpandProperty Tag
       
       #Check Replication tag for "Replication-Yes"
       if ($validate -like '*Replication-Yes') {
            write-host "`tReplication-Yes Set for $vm" -ForegroundColor Cyan
            $rpo = Get-TagAssignment -Entity $vm -cat "RPO" | Select -ExpandProperty Tag
            if ($rpo -eq $null) {
                #if no RPO Tag, assign RPO24
                New-TagAssignment -Tag "RPO-24 Hours"� -Entity $VM
                write-host "`t`tRPO-24 Hours assigned to host $vm" -ForegroundColor White
                $tagchanges = $tagchanges + "RPO-24 Hours assigned to host $vm`n"
                $rpo24 = $rpo24 + '$vm`n'
                    
            } else {
                write-host "`t`t$rpo for host $vm" -ForegroundColor Gray
                if($rpo -like '*24*') {
                    $rpo24 = $rpo24 + "$vm, "
                } elseif ($rpo -like  '*12*') {
                    $rpo12 = $rpo12 + "$vm, "
                } elseif ($rpo -like  '*4*') {
                    $rpo4 = $rpo4 + "$vm, "
                }
            }  

            #split the host name, and trim any whitespace from it, then contatenate the suffix to the tag.
            $thishost = $vmhost.split(".")
            $thishost =  $thishost[0].trim()
            $RRStag = Get-TagAssignment -Entity $vm -cat "Remote Replication Source" | Select -ExpandProperty Tag
            $RRSnewtag = "Remote Replication Source/$thishost$suffix"
            if ($RRSnewtag -like $RRStag) {
                Write-host "`t`tCurrent tag matches VMHost for $vm" -ForegroundColor Magenta
            } else {
                #if new datastore tag is present, assign the current VMHost tag
                if ($RRStag -eq $null) {
                    New-TagAssignment -Tag $thishost$suffix -Entity $vm 
                    Write-Host "`tAssign Tag '$newtag' on Target $vm" -ForegroundColor Green
                    $tagchanges = $tagchanges + "Assign Tag '$newtag' on Target $vm`n"
                }
                $tagmismatch = $tagmismatch + "Current tag: Warning '$RRStag' does not match new tag: '$RRSnewtag' on target $vm`n"
            }
       } else {
            #if Replication-NO tag found

            #split and trim the VMhost name to allow for tag creation / check
            $thishost = $vmhost.split(".")
            $thishost =  $thishost[0].trim()
            $thishost = $thishost.ToUpper()
            
            $rpo = Get-TagAssignment -Entity $vm -cat "RPO" | Select -ExpandProperty Tag
            if ($rpo -ne $null) {
                Get-TagAssignment -Entity $vm -cat "RPO" | Remove-TagAssignment -Confirm:$false
                write-host "`t`tRPO tag removed from host $vm" -ForegroundColor Red
                $tagchanges = $tagchanges + "$vm : RPO tag removed from host`n"
            } 
            
            #check the replication tag, if it's null re-write it with "Replication-No".
            #check for _replica in VM name
            if ($vm -like '*_replica' -or $VM -like '*COVBR*' -or $VM -like '*POVBR*') {
                Write-host "`tNo Replication for $vm" -ForegroundColor Gray
                #check for an RPO tag, and remove it.
                $removeRPO = Get-TagAssignment -Entity $vm -cat "RPO" | Select -ExpandProperty Tag
                    if ($removeRPO -ne $null) {
                        Get-TagAssignment -Entity $vm -cat "RPO" | Remove-TagAssignment -Confirm:$false
                        write-host "`t`tRPO: RPO tag removed from $vm" -ForegroundColor Red
                        $tagchanges = $tagchanges + "'RPO tag removed from host $vm`n"
                    } 
                #check the back type is set to 'Backup-No Backup' if not set it.
                $BTCheck = Get-TagAssignment -Entity $vm -cat "Backup Type" | Select -ExpandProperty Tag
                if ($BTCheck -eq $null) {
                    New-TagAssignment -Tag “Backup-No Backup” -Entity $VM
                    Write-Host "`tAssigned Tag 'Backup-No Backup' on Target $vm" -ForegroundColor Green
                    $tagchanges = $tagchanges + "Backup Tag set to 'Backup-No Backup' on target $vm`n"
                }
            } else {
                
                #if Replication tag is "NO" but not a "*_replica"
                
                if ($validate -eq $null) {
                    #if no replication tag set set the defualt of 'Replication-No'
                    Write-Host "`t No Replication tag set for $VM" -ForegroundColor Red
                    New-TagAssignment -Tag “Replication-No” -Entity $VM 
                    Write-Host "`tAssign Tag 'Replication-No' on Target $vm" -ForegroundColor Green
                    $tagchanges = $tagchanges + "$vm : Assigned Tag 'Replication-No' on Target`n"
                    $RRStag = Get-TagAssignment -Entity $vm -cat "Remote Replication Source" | Select -ExpandProperty Tag
                    $RRSnewtag = "$thishost$suffix"
                    if ($RRSnewtag -like $RRStag) {
                        Write-host "`t`tCurrent tag matches VMHost for $vm" -ForegroundColor Magenta
                    } else {
                        if ($RRStag -eq $null) {
                            New-TagAssignment -Tag $thishost$suffix -Entity $vm 
                            Write-Host "`tAssigned Tag '$thishost$suffix' on Target $vm" -ForegroundColor Green
                            $tagchanges = $tagchanges + "$vm : Assigned Tag '$thishost$suffix' on Target`n"
                        }
                    }
                    Write-host "`tCurrent tag: Warning '$RRStag' does not match new tag: '$RRSnewtag' on target $vm" -ForegroundColor Red
                     $tagmismatch = $tagmismatch + "$vm : Warning '$RRStag' does not match new tag: '$RRSnewtag' `n"
                } else {
                    #has 'Replication-No'
                    Write-Host "`tReplication-No set for $VM" -ForegroundColor DarkCyan
                    $RRStag = Get-TagAssignment -Entity $vm -cat "Remote Replication Source" | Select -ExpandProperty Tag
                    $RRSnewtag = "Remote Replication Source/$thishost$suffix"
                    #check the datastore tag matches the VMHost.
                    if ($RRSnewtag -like $RRStag) {
                        Write-host "`t`tCurrent tag matches VMHost for $vm" -ForegroundColor DarkMagenta
                    } else {
                        if ($RRStag -eq $null) {
                            New-TagAssignment -Tag $thishost$suffix -Entity $vm 
                            Write-Host "`tAssign Tag '$thishost$suffix' on Target $vm" -ForegroundColor Green
                            $tagchanges = $tagchanges + "$vm : Assigned Tag '$thishost$suffix' on Target`n"
                        }
                        Write-host "`tCurrent tag: Warning '$RRStag' does not match new tag: '$RRSnewtag' on target $vm" -ForegroundColor Red
                        $tagmismatch = $tagmismatch + "$vm : Warning '$RRStag' does not match new tag: '$RRSnewtag' `n"
                    }
                }
                    $BTCheck = Get-TagAssignment -Entity $vm -cat "Backup Type" | Select -ExpandProperty Tag
                    if ($BTCheck -like '*-No*') {
                        $nobackup = $nobackup + "$vm, "
                    }
                }
        }    
    }

#Compile Report to email
if ($rpo24 -gt $null -or $rpo12 -gt $null -or $rpo4 -gt $null -or $tagchanges -gt $null -or $tagmismatch -gt $null -or $storageerror -gt $null) {
    Add-Content $replog " "
    Add-Content $replog "Processing host: $vmhost"
    Add-Content $replog "========================="
}
if ($rpo24 -gt $null) {
    Add-content $replog "RPO24: $rpo24"
    }
if ($rpo12 -gt $null) {
    Add-content $replog "RPO12: $rpo12"
    }
if ($rpo4 -gt $null) {
    Add-content $replog "RPO4: $rpo4"
    }
if ($tagchanges -gt $null) {
    add-content $replog " "
    Add-content $replog "Tag Changes"
    Add-content $replog $tagchanges
    }
if ($tagmismatch -gt $null) {
    add-content $replog " "
    Add-content $replog "Tag Mismatches"
    Add-content $replog $tagmismatch
    add-content $replog " "
    }
if ($Storageerror -gt $null) {
    Add-content $replog "Storage Tags"
    Add-content $replog $storageerror
    add-content $replog " "
    }

#null out set variables
$rpo24 = $null
$rpo12 = $null
$rpo4 = $null

}

if ($nobackup -gt $null) {
    Add-content $replog " "
    Add-content $replog "No Backup set on these VM's"
    Add-content $replog "==========================="
    Add-content $replog $nobackup
    Add-content $replog " "
}

#tag daily log with end date
$enddate = get-date -Format "dd/MM/yy HH:mm:ss"
Add-Content $replog "Tag analysis finished: $enddate"
    
    #Send dailychecks log to Veeam Admins
    $From = "VMtaganalysis@yourdomain.co.uk"
    $To = "Veeam.Admins@yourdomain.co.uk"
    $Attachment = $replog
    $Subject = "VM Tag Analysis"
    $Body = "The Tag analysis scripts has completed, please check the attached daily log file for more information"
    $SMTPServer = "exchange.server.local"
    $SMTPPort = "25"
    Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -Attachments $Attachment -DeliveryNotificationOption OnSuccess
    
#remove the DailyChecks.log files
remove-item -Path $replog -Force

