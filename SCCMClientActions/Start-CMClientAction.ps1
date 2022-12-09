    <#
          SCCM Client Action Trigger Codes
          --------------------------------

          1 - {00000000-0000-0000-0000-000000000001} Hardware Inventory - (ConfigMgr Control Panel Applet - Hardware Inventory Cycle)
          2 - {00000000-0000-0000-0000-000000000002} Software Inventory - (ConfigMgr Control Panel Applet - Software Inventory Cycle)
          3 - {00000000-0000-0000-0000-000000000003} Discovery Inventory - (ConfigMgr Control Panel Applet - Discovery Data Collection Cycle)
          4 - {00000000-0000-0000-0000-000000000010} File Collection - (ConfigMgr Control Panel Applet - File Collection Cycle)
          5 - {00000000-0000-0000-0000-000000000011} IDMIF Collection 
          6 - {00000000-0000-0000-0000-000000000012} Client Machine Authentication 
          7 - {00000000-0000-0000-0000-000000000021} Request Machine Assignments - (ConfigMgr Control Panel Applet - Machine Policy Retrieval & Evaluation Cycle) 
          8 - {00000000-0000-0000-0000-000000000022} Evaluate Machine Policies 
          9 - {00000000-0000-0000-0000-000000000023} Refresh Default MP Task 
          10 - {00000000-0000-0000-0000-000000000024} LS (Location Service) Refresh Locations Task 
          11 - {00000000-0000-0000-0000-000000000025} LS (Location Service) Timeout Refresh Task 
          12 - {00000000-0000-0000-0000-000000000026} Policy Agent Request Assignment (User) 
          13 - {00000000-0000-0000-0000-000000000027} Policy Agent Evaluate Assignment (User) - (ConfigMgr Control Panel Applet - User Policy Retrieval & Evaluation Cycle)
          14 - {00000000-0000-0000-0000-000000000031} Software Metering Generating Usage Report 
          15 - {00000000-0000-0000-0000-000000000032} Source Update Message - (ConfigMgr Control Panel Applet - Windows Installer Source List Update Cycle)
          16 - {00000000-0000-0000-0000-000000000037} Clearing Proxy Settings Cache 
          17 - {00000000-0000-0000-0000-000000000040} Machine Policy Agent Cleanup 
          18 - {00000000-0000-0000-0000-000000000041} User Policy Agent Cleanup
          19 - {00000000-0000-0000-0000-000000000042} Policy Agent Validate Machine Policy/Assignment 
          20 - {00000000-0000-0000-0000-000000000043} Policy Agent Validate User Policy/Assignment 
          21 - {00000000-0000-0000-0000-000000000051} Retrying/Refreshing Certificates in AD on MP 
          22 - {00000000-0000-0000-0000-000000000061} Peer DP Status Reporting 
          23 - {00000000-0000-0000-0000-000000000062} Peer DP Pending Package Check Schedule 
          24 - {00000000-0000-0000-0000-000000000063} SUM Updates Install Schedule 
          25 - {00000000-0000-0000-0000-000000000071} NAP action 
          26 - {00000000-0000-0000-0000-000000000101} Hardware Inventory Collection Cycle 
          27-  {00000000-0000-0000-0000-000000000102} Software Inventory Collection Cycle 
          28 - {00000000-0000-0000-0000-000000000103} Discovery Data Collection Cycle 
          29 - {00000000-0000-0000-0000-000000000104} File Collection Cycle 
          30 - {00000000-0000-0000-0000-000000000105} IDMIF Collection Cycle 
          31 - {00000000-0000-0000-0000-000000000106} Software Metering Usage Report Cycle 
          32 - {00000000-0000-0000-0000-000000000107} Windows Installer Source List Update Cycle 
          33 - {00000000-0000-0000-0000-000000000108} Software Updates Assignments Evaluation Cycle - (ConfigMgr Control Panel Applet - Software Updates Deployment Evaluation Cycle) 
          34 - {00000000-0000-0000-0000-000000000109} Branch Distribution Point Maintenance Task 
          35 - {00000000-0000-0000-0000-000000000110} DCM Policy 
          36 - {00000000-0000-0000-0000-000000000111} Send Unsent State Message 
          37 - {00000000-0000-0000-0000-000000000112} State System Policy Cache Cleanout 
          38 - {00000000-0000-0000-0000-000000000113} Scan by Update Source - (ConfigMgr Control Panel Applet - Software Updates Scan Cycle)
          39 - {00000000-0000-0000-0000-000000000114} Update Store Policy 
          40 - {00000000-0000-0000-0000-000000000115} State System Policy Bulk Send High
          41 - {00000000-0000-0000-0000-000000000116} State System Policy Bulk Send Low 
          42 - {00000000-0000-0000-0000-000000000120} AMT Status Check Policy 
          43 - {00000000-0000-0000-0000-000000000121} Application Manager Policy Action - (ConfigMgr Control Panel Applet - Application Deployment Evaluation Cycle)
          44 - {00000000-0000-0000-0000-000000000122} Application Manager User Policy Action
          45 - {00000000-0000-0000-0000-000000000123} Application Manager Global Evaluation Action 
          46 - {00000000-0000-0000-0000-000000000131} Power Management Start Summarizer
          47 - {00000000-0000-0000-0000-000000000221} Endpoint Deployment Reevaluate 
          48 - {00000000-0000-0000-0000-000000000222} Endpoint AM Policy Reevaluate 
          49 - {00000000-0000-0000-0000-000000000223} External Event Detection
    #>
    Function Run-SCCMClientAction {
        [CmdletBinding()]
                
        # Parameters used in this function
        param
        ( 
            [Parameter(Position=0, Mandatory = $True, HelpMessage="Provide server names", ValueFromPipeline = $true)] 
            [string[]]$Computername,
 
           [ValidateSet('MachinePolicy', 
                        'DiscoveryData', 
                        'ComplianceEvaluation', 
                        'AppDeployment',  
                        'HardwareInventory', 
                        'UpdateDeployment', 
                        'UpdateScan', 
                        'SoftwareInventory')] 
            [string[]]$ClientAction
   
        ) 
        $ActionResults = @()
        Try { 
                $ActionResults = Invoke-Command -ComputerName $Computername {param($ClientAction)
 
                        Foreach ($Item in $ClientAction) {
                            $Object = @{} | Select-Object "Action name",Status
                            Try{
                                $ScheduleIDMappings = @{ 
                                    'MachinePolicy'        = '{00000000-0000-0000-0000-000000000021}'; 
                                    'DiscoveryData'        = '{00000000-0000-0000-0000-000000000003}'; 
                                    'ComplianceEvaluation' = '{00000000-0000-0000-0000-000000000071}'; 
                                    'AppDeployment'        = '{00000000-0000-0000-0000-000000000121}'; 
                                    'HardwareInventory'    = '{00000000-0000-0000-0000-000000000001}'; 
                                    'UpdateDeployment'     = '{00000000-0000-0000-0000-000000000108}'; 
                                    'UpdateScan'           = '{00000000-0000-0000-0000-000000000113}'; 
                                    'SoftwareInventory'    = '{00000000-0000-0000-0000-000000000002}'; 
                                }
                                $ScheduleID = $ScheduleIDMappings[$item]
                                Write-Verbose "Processing $Item - $ScheduleID"
                                [void]([wmiclass] "root\ccm:SMS_Client").TriggerSchedule($ScheduleID);
                                $Status = "Success"
                                Write-Verbose "Operation status - $status"
                            }
                            Catch{
                                $Status = "Failed"
                                Write-Verbose "Operation status - $status"
                            }
                            $Object."Action name" = $item
                            $Object.Status = $Status
                            $Object
                        }
 
            } -ArgumentList $ClientAction -ErrorAction Stop | Select-Object @{n='ServerName';e={$_.pscomputername}},"Action name",Status
        }  
        Catch{
            Write-Error $_.Exception.Message 
        }   
        Return $ActionResults           
 } 

<# 
 #Single action on 1 computer
Run-SCCMClientAction -Computername DC01 -ClientAction AppDeployment
 
#Single action on multiple servers
Run-SCCMClientAction -Computername (Get-Content .\input.txt) -ClientAction SoftwareInventory
 
#Multiple actions  on multiple servers
Run-SCCMClientAction -Computername (Get-Content .\input.txt) -ClientAction AppDeployment,ComplianceEvaluation,SoftwareInventory
 
#Multiple actions with verbose mode  on multiple servers
Run-SCCMClientAction -Computername (Get-Content .\input.txt) -ClientAction AppDeployment,ComplianceEvaluation,DiscoveryData,SoftwareInventory -Verbose
#>

$pc = read-host "enter pc / server name"

Run-SCCMClientAction -Computername $pc -ClientAction UpdateScan -verbose
Run-SCCMClientAction -Computername $pc -ClientAction UpdateDeployment -verbose
Run-SCCMClientAction -Computername $pc -ClientAction MachinePolicy -verbose
Run-SCCMClientAction -Computername $pc -ClientAction SoftwareInventory -verbose

Write-Host "`n Client Actions Ran " -BackgroundColor DarkGreen -ForegroundColor Yellow


