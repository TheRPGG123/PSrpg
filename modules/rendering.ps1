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

# function for printing the game window
function printWorld {
    param($map)
    Clear-Host
    Write-Host $gameWindow -ForegroundColor Gray

    # calculate camera origin
    $halfW = [math]::Floor($viewPortWidth / 2)
    $halfH = [math]::Floor($viewPortHeight / 2)
    $origX = [math]::Max(0, [math]::Min($script:player.x - $halfW, $script:worldParameters.width - $viewPortWidth))
    $origY = [math]::Max(0, [math]::Min($script:player.y - $halfH, $script:worldParameters.height - $viewPortHeight))

    # draw all visible tiles
    foreach ($t in $map) {
        if ($t.x -ge $origX -and $t.x -lt $origX + $viewPortWidth -and $t.y -ge $origY -and $t.y -lt $origY + $viewPortHeight) {
            printItem -printable $t -origX $origX -origY $origY
        }
    }

    # draw all the locations on top of the tiles
    foreach ($place in $script:worldLocations) {
        if (ifInViewport -printable $place -origX $origX -origY $origY) {
            printItem -printable $place   -origX $origX -origY $origY
        }
    }
    
    printItem -printable $script:player -origX $origX -origY $origY
}

function printMap {
    param(
        [PSCustomObject]$location # your location or world object
    )
    Clear-Host
    Write-Host $gameWindow -ForegroundColor Gray

    # pull dimensions & tiles out of the location
    $mapTiles = $location.map
    $mapWidth = $location.width
    $mapHeight = $location.height

    # camera math
    $halfW = [math]::Floor($viewPortWidth / 2)
    $halfH = [math]::Floor($viewPortHeight / 2)
    $origX = [math]::Max(0, [math]::Min($script:player.x - $halfW, $mapWidth - $viewPortWidth))
    $origY = [math]::Max(0, [math]::Min($script:player.y - $halfH, $mapHeight - $viewPortHeight))

    # draw the base map
    foreach ($tile in $mapTiles) {
        if ($tile.x -ge $origX -and $tile.x -lt $origX + $viewPortWidth `
                -and $tile.y -ge $origY -and $tile.y -lt $origY + $viewPortHeight) {
            printItem -printable $tile -origX $origX -origY $origY
        }
    }
    
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

