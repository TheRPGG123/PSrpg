
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
$mapWidth = 7
$mapHeight = 7
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
    param ($printable)
    [System.Console]::SetCursorPosition($printable.x + 1, $printable.y + 1)
    Write-Host $printable.print -ForegroundColor $printable.color
}

# making a map
function GenerateWorld {
    param ($world)

    $worldBlocks = ',.;:'
    for ($x = 0; $x -lt $mapWidth; $x++) {
        for ($y = 0; $y -lt $mapHeight; $y++) {
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
    param ($world)

    Write-Host $gameWindow
    # printing the world map
    foreach ($tile in $world) {
        printItem -printable $tile
    }

    # printing out the player
    printItem -printable $item

    printItem -printable $player
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
        'w' { if ($player.y -gt 0) { $player.y-- } }
        'a' { if ($player.x -gt 0) { $player.x-- } }
        's' { if ($player.y -lt $mapHeight - 1) { $player.y++ } }
        'd' { if ($player.x -lt $mapWidth - 1) { $player.x++ } }
        'e' {  }

        'p' { 
            clear-Host
            return
        }
        Default {}
    }
}