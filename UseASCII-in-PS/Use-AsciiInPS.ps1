$greentick = @{
  Object = [Char]10004
  ForegroundColor = 'Green'
  }

$eggtimer = @{
    object = [Char]9203
    ForegroundColor = 'white'
    }

$Skull = @{
    object = [Char]9760
    Foregroundcolor = 'Gray'
    }

$smallHappy = @{
    #object = [Char]9786
    object = [char]0x263a
    #Object = [char]0x263b
    ForegroundColor = 'Green'
    }

$bigunhappy = @{
    object = [Char]9785
    ForegroundColor = 'red'
    }

Write-host @greentick
Write-host @eggtimer
Write-host @Skull
Write-host @smallHappy
Write-host @bigunhappy
