#example: find the date of the next satruday

$daytofind = 'Saturday'
$i = 0 

do {
    $i++
    $futureday = (get-date).AddDays($i) | select date, Dayofweek
    if ($futureday.DayofWeek -eq $daytofind) {
        Write-host "The next $daytofind is"$($futureday).date
        break
    }
} until ($(($futureday).Dayofweek) -eq $daytofind)
