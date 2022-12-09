#author: Richard Easton
#description: link a server/s to an azure workspace 
#usage: add-mmaworksapce -workspaceid "acbd1234-0000-1a2b-1234-abc1d2345678" -workspacekey [yourkey] -compuntername [yourserver] 
#optional: $credentials, use get-credential in the normal way
#optional: can be used in a foreach loop


function Add-MMAWorkspace {
    [cmdletbinding(SupportsShouldProcess)]
    param
  (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $workspaceId,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $workspaceKey,

    # add parameters for computername
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]] $ComputerName,
    
    [PSCredential]
    $Credential - get-credential
  )
    if ($PSCmdlet.ShouldProcess($computername, $workspaceId, $workspacekey)) {
        $mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        $mma.AddCloudWorkspace($workspaceId, $workspaceKey)
        $mma.ReloadConfiguration()
    }
}
