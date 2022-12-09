function Count-GroupMembers {
    [cmdletbinding()]
        param (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $Groupname,
         [Parameter(Mandatory=$true, Position=1)]
         [ValidateSet('Group','Members')]
         $sortby
            
        )
    $array = @()
    $groups = Get-ADGroup -Filter * | where {$_.name -like $groupname} | Select -ExpandProperty Name 

    foreach ($group in $groups) {
        $users = Get-ADGroup -identity $group | Get-ADGroupMember | Select SamaccountName
        $output = [pscustomobject]@{
            Group = $group
            Members = $users.Count
        }
        $array += $output
    }

    $array = $array | Sort-object $sortby
    $array
}
