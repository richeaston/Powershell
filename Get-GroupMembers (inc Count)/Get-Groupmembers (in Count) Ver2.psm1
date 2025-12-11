function Get-GroupMemberCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Groupname,

        [Parameter(Position=1)]
        [ValidateSet('Group','Members')]
        [string]$SortBy = 'Members' # Default sort by count
    )

    process {
        $FilterStr = "Name -like '$Groupname'"
        $Results = Get-ADGroup -Filter $FilterStr -Properties Members | ForEach-Object {
        $MemberCount = if ($_.Members) { $_.Members.Count } else { 0 }

            [PSCustomObject]@{
                Group   = $_.Name
                Members = $MemberCount
            }
        }

        if ($Results) {
            $Results | Sort-Object $SortBy -Descending
        }
    }
}
