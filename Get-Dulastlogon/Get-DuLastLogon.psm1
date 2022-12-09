# Usage: Get-DUlastLogon

Function Get-DUlastlogin() {
    Clear-host
    $users = @()
    $path = "C:\Users"
    $dirs = get-childitem -Path $path -Recurse -Depth 0 -Directory | select fullname, Pschildname, LastAccessTime, LastWritetime | sort-object LastAccesstime -Descending
    foreach ($dir in $dirs) {
        if ($dir.PSChildName -Ne 'Administrator' -and $dir.PSChildName -ne 'public') {
            $ntuser = Get-ChildItem -Path $dir.FullName -filter "NTUSER.DAT" -depth 0 -file -Attributes hidden | Select PSChildname, LastWriteTime, LastAccesstime | sort-object Lastaccesstime -Descending
            foreach ($N in $ntuser) {
                $user = [pscustomobject]@{
                    Username = $dir.PSChildName
                    LastfolderAccess = $(get-date($($dir.lastaccesstime)) -format "dd/MM/yy hh:mm:ss")
                    #LastfolderWrite = $(get-date($($dir.lastwritetime)) -format "dd/MM/yy hh:mm:ss")
                    NTUserlastAccess = $(get-date($($n.lastAccesstime)) -format "dd/MM/yy hh:mm:ss")
                    #NTUserlastWrite = $(get-date($($n.lastwritetime)) -format "dd/MM/yy hh:mm:ss")
                }
            $users+= $user
            }
        }
    }
    $users | FT -AutoSize
}
