#author: Richard Easton
#description: unlink a server/s from an azure workspace 
#usage: remove-mmaworksapce -workspaceid "acbd1234-0000-1a2b-1234-abc1d2345678" -computername [yourserver] 
#optional: $credentials, use get-credential in the normal way
#optional: can be used in a foreach loop

function Remove-MMAWorkspace {
  [cmdletbinding(SupportsShouldProcess)]
  param
  (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $workspaceId,
    
    # add parameters for computername and credentials:
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $ComputerName,
    
    [PSCredential]
    $Credential
  )
    if ($PSCmdlet.ShouldProcess($computername, $workspaceId)) {
        $mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
        $mma.RemoveCloudWorkspace($workspaceId)
        $mma.ReloadConfiguration()
    }
}

