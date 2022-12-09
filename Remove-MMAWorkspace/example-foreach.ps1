function Remove-MMAWorkspace ($workspaceId) {
    try {
    $mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
    $mma.RemoveCloudWorkspace($workspaceId)
    $mma.ReloadConfiguration()
    Write-host "`tRemoved $workspaceId"
    }
    catch {
        Write-warning "Something went wrong"
    }
}

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

write-host "Current directory is: $dir"
$servers = get-content "$dir\servers.csv"
$workspaceId = '[workspace ID here]'
foreach ($s in $servers) {
    Write-host "Processing $s"
    Invoke-Command  -ScriptBlock ${Function:Remove-MMAWorkspace} -ArgumentList "$workspaceId" -computername $S
}
