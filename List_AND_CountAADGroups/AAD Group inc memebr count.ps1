Clear-Host

Connect-AzureAD
$output = @()
$groups = Get-AzureADMSGroup -all $true |  where {$_.DisplayName -like '*[your_group_here]*'} | Select ID, Displayname | sort-object Displayname



foreach ($group in $groups){
        $subcount = 0 
        Write-host "$($Group.DisplayName)" -ForegroundColor Yellow
        
        $subgroups = Get-AzureADGroupMember -ObjectId $group.Id | Select DisplayName -unique | Sort-Object Displayname 
        foreach ($subgroup in $subgroups) {
            $subdetails = Get-AzureADMSGroup -SearchString $($subgroup.DisplayName) -All $true -verbose | Select ID, DisplayName -First 1 | sort-object DisplayName
            foreach ($subd in $subdetails) {
                $subsubgroups = Get-AzureADGroupMember -ObjectId $subdetails.Id -all $true | where {$_.Objecttype -eq "Group"} | Select ID ,DisplayName -unique | Sort-Object Displayname 
                if ($subsubgroups) {
                    foreach ($subsubd in $subsubgroups) {
                        $subsubdetails = Get-AzureADMSGroup -SearchString $($subsubd.DisplayName) -All $true -verbose | Select ID, DisplayName -First 1 | sort-object DisplayName
                        $AADGroupDetails = (Get-AzureADGroupMember -ObjectId $subsubdetails.ID -all 1).count
                        Write-Host "`t`t$($subsubd.DisplayName) : $($AADGroupDetails)" -ForegroundColor Gray
                        $subcount += $AADGroupDetails
                    }
                }
                           
                $AADGroupDetails = (Get-AzureADGroupMember -ObjectId $subd.ID -all 1).count
                Write-host "`t$($subgroup.DisplayName) : $($AADGroupDetails)" -ForegroundColor Magenta
                $subcount += $AADGroupDetails
                
            }
        }   
            
        $Groupdetails = [PSCustomObject]@{
            Name = $Group.DisplayName
            Members = $subcount
        }
        $output += $Groupdetails   
        
}

$output | sort-object Name
$output | Out-GridView -Title "Current groups (inc count)"
