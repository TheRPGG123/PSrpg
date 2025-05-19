$gameWindow = @'
+-------+-------------+
|       |             |
|       |             |
|       |             |
|       |             |
|       |             |
|       |             |
|       |             |
+-------+-------------+
'@

$viewPortWidth = 7
$viewPortHeight = 7

# checks is an item is in viewport to draw it or not
function ifInViewport {
    param(
        [PSCustomObject]$printable,
        [int]$origX = 0,
        [int]$origY = 0
    )
    if ($printable.x -ge $origX -and $printable.x -lt $origX + $viewPortWidth -and $printable.y -ge $origY -and $printable.y -lt $origY + $viewPortHeight) {
        return $true
    }
}

# printing all the ground items from the array
function printGroundItems {
    param($groundItems)
    foreach ($item in $groundItems) {
        if ($item.location -eq $script:player.location -and (ifInViewport -printable $item -origX $origX -origY $origY)) {
            printItem -printable $item   -origX $origX -origY $origY
        }
    }
}

# simple function to print out objects with 4 most important items: x, y, print and color
function printItem {
    param(
        [PSCustomObject]$printable,
        [int]$origX = 0,
        [int]$origY = 0
    )
    # compute screen position (+1 for the ASCII border)
    
    [Console]::SetCursorPosition(($printable.x - $origX) + 1, ($printable.y - $origY) + 1)
    Write-Host $printable.print -ForegroundColor $printable.color
}

function printLocations {
    param($locations)
    foreach ($place in $locations) {
        if ($place.location -eq $script:player.location -and (ifInViewport -printable $place -origX $origX -origY $origY)) {
            printItem -printable $place   -origX $origX -origY $origY
        }
    }
}

# function for printing the game window
function PrintMap {
    param($map)
    Clear-Host
    Write-Host $gameWindow

    # calculate camera origin
    $halfW = [math]::Floor($viewPortWidth / 2)
    $halfH = [math]::Floor($viewPortHeight / 2)
    $origX = [math]::Max(0, [math]::Min($script:player.x - $halfW, $script:worldParameters.width - $viewPortWidth))
    $origY = [math]::Max(0, [math]::Min($script:player.y - $halfH, $script:worldParameters.height - $viewPortHeight))

    # draw all visible tiles
    foreach ($t in $world) {
        if ($t.x -ge $origX -and $t.x -lt $origX + $viewPortWidth -and $t.y -ge $origY -and $t.y -lt $origY + $viewPortHeight) {
            printItem -printable $t -origX $origX -origY $origY
        }
    }

    # draw the item and script:player via the same helper 
    printGroundItems -groundItems $script:groundItems

    printLocations -locations $script:worldLocations
    
    printItem -printable $script:player -origX $origX -origY $origY
}

# printing HUD and all of it's elements
function PrintHud {
    param ($health, $stamina)
    [System.Console]::SetCursorPosition(9, 1)
    Write-Host "HP: ◼◼◼◼◼◼◼◼" -ForegroundColor Red

    [System.Console]::SetCursorPosition(9, 3)
    Write-Host "x:$($script:player.x), y:$($script:player.y)"
}
