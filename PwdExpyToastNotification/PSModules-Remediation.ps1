

# *************************************************************************************
# 								Install modules	
# *************************************************************************************		
$Is_Nuget_Installed = $False     
If(!(Get-PackageProvider | where {$_.Name -eq "Nuget"}))
	{                                         
		Try
			{
				[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
				Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force -Confirm:$False | out-null                                                                                                                 
				$Is_Nuget_Installed = $True                                                                                     
			}
		Catch
			{
				Break
			}
	}
Else
	{
		$Is_Nuget_Installed = $True      
	}

If($Is_Nuget_Installed -eq $True)
	{
		$Script:Module_Status = $False
		$Module_Name = "RunasUser"
		If (!(Get-InstalledModule $Module_Name -ErrorAction silentlycontinue)) 				
			{ 
				Install-Module $Module_Name -Force -AllowClobber -Scope AllUsers -Confirm:$False -ErrorAction SilentlyContinue | out-null   
				$Module_Version = (Get-Module $Module_Name -listavailable).version
				$Module_Status = $True
						                                                                                                                                                                                                                 
			} 
		Else
			{                                                                                                                                                                  
				Import-Module $Module_Name -Force -ErrorAction SilentlyContinue -Verbose
				write-host "$Module_Name present"
                $Module_Status = $True	                                                  
			}  

        $Script:Module_Status = $False
		$Module_Name = "MSOnline"
		If (!(Get-InstalledModule $Module_Name -ErrorAction silentlycontinue)) 				
			{ 
				Install-Module $Module_Name -Force -AllowClobber -Scope AllUsers -Confirm:$False -ErrorAction SilentlyContinue | out-null   
				$Module_Version = (Get-Module $Module_Name -listavailable).version
				$Module_Status = $True								                                                                                                                                                                                                                 
			} 
		Else
			{                                                                                                                                                                  
				Import-Module $Module_Name -Force -ErrorAction SilentlyContinue -Verbose
				write-host "$Module_Name present"
                $Module_Status = $True	                                                  
			}  
        
        $Script:Module_Status = $False
		$Module_Name = "AzureAD"
		If (!(Get-InstalledModule $Module_Name -ErrorAction silentlycontinue)) 				
			{ 
				Install-Module $Module_Name -Force -AllowClobber -Scope AllUsers -Confirm:$False -ErrorAction SilentlyContinue | out-null   
				$Module_Version = (Get-Module $Module_Name -listavailable).version
				$Module_Status = $True								                                                                                                                                                                                                                 
			} 
		Else
			{                                                                                                                                                                  
				Import-Module $Module_Name -Force -ErrorAction SilentlyContinue -Verbose
				write-host "$Module_Name present"
                $Module_Status = $True	                                                  
			}  
                                                     
	}

exit 0
