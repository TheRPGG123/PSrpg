
## setting up encoding and some console quality of life
chcp 65001
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()
[Console]::InputEncoding = [Text.UTF8Encoding]::new()
[Console]::CursorVisible = $false

Clear-Host

## setup of initial important parameters
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
$worldWidth = 14
$worldHeight = 14
$world = @()

# player object
$player = [PSCustomObject]@{
    print = '@'
    class = 'none'
    color = 'white'
    x     = 3
    y     = 3
}

# first item object, later do this with a .json file
$item = [PSCustomObject]@{
    print       = '☐'
    name        = 'square'
    description = 'Not really sure waht it is, but it menaces with some dark energy...'
    color       = 'yellow'
    x           = 2
    y           = 2
}

# functions:
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

# making a map
function GenerateWorld {
    param ($world)

    $worldBlocks = ',.;:'
    for ($x = 0; $x -lt $worldWidth; $x++) {
        for ($y = 0; $y -lt $worldHeight; $y++) {
            $world += [PSCustomObject]@{
                print = $worldBlocks[$(Get-Random -Maximum 3)]
                info  = 'grass'
                color = 'green'
                x     = $x
                y     = $y
            }
        }
    }
    return $world
}

# function for printing the game window
function PrintMap {
    param($world)
    Clear-Host
    Write-Host $gameWindow

    # calculate camera origin
    $halfW = [math]::Floor($viewPortWidth / 2)
    $halfH = [math]::Floor($viewPortHeight / 2)
    $origX = [math]::Max(0, [math]::Min($player.x - $halfW, $worldWidth - $viewPortWidth))
    $origY = [math]::Max(0, [math]::Min($player.y - $halfH, $worldHeight - $viewPortHeight))

    # draw all visible tiles
    foreach ($t in $world) {
        if ($t.x -ge $origX -and $t.x -lt $origX + $viewPortWidth -and $t.y -ge $origY -and $t.y -lt $origY + $viewPortHeight) {
            printItem -printable $t -origX $origX -origY $origY
        }
    }

    # draw the item and player via the same helper
    if (ifInViewport -printable $item -origX $origX -origY $origY) {
        printItem -printable $item   -origX $origX -origY $origY
    }
    
    printItem -printable $player -origX $origX -origY $origY
}

function PrintHud {
    param ($health, $stamina)
    [System.Console]::SetCursorPosition(9, 1)
    Write-Host "HP: ◼◼◼◼◼◼◼◼" -ForegroundColor Red
}

# calling world generation
$world = GenerateWorld -world $world

# test game loop
while ($true) {
    Clear-Host
    PrintMap -world $world
    PrintHud -health 2 -stamina 2
    $pressedButton = [Console]::ReadKey($true)
    switch ($pressedButton.KeyChar) {
        'w' { if ($player.y -gt 0                   ) { $player.y-- } }
        's' { if ($player.y -lt $worldHeight - 1    ) { $player.y++ } }
        'a' { if ($player.x -gt 0                   ) { $player.x-- } }
        'd' { if ($player.x -lt $worldWidth - 1    ) { $player.x++ } }
        'e' { }
        'p' { Clear-Host; return }
        Default {}
    }
}