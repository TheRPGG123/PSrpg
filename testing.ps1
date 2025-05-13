
## setting up encoding and some console quality of life
chcp 65001
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()
[Console]::InputEncoding = [Text.UTF8Encoding]::new()
[Console]::CursorVisible = $false

Add-Type -Path ".\Libnoise\LibNoise.dll"

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
$worldWidth = 50
$worldHeight = 50
$world = @()

# player object
$player = [PSCustomObject]@{
    print = '@'
    class = 'none'
    color = 'white'
    x     = 7
    y     = 7
}
$script:playerInventory = @(
    [PSCustomObject]@{
        print       = '/'
        name        = 'Iron Sword'
        description = '+5 Attack, reliable blade'
        color       = 'Gray'
    }
    [PSCustomObject]@{
        print       = 'O'
        name        = 'Wooden Shield'
        description = '+3 Defense, lightweight'
        color       = 'DarkYellow'
    }
    [PSCustomObject]@{
        print       = '!'
        name        = 'Health Potion'
        description = 'Restores 50 HP'
        color       = 'Red'
    }
)

# first item object, later do this with a .json file
$script:groundItems = @(
    [PSCustomObject]@{
        print       = '☐'
        name        = 'Square'
        description = 'Not really sure waht it is, but it menaces with some dark energy...'
        color       = 'yellow'
        x           = 2
        y           = 2
    },
    [PSCustomObject]@{
        print       = '/'
        name        = 'Iron Sword'
        description = '+5 Attack, reliable blade'
        color       = 'Gray'
        x           = 5
        y           = 5
    }
)

## functions:
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

# making a map
function GenerateWorld {
    param ($world)

    Write-Host "Generating..."
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

# printing all the ground items from the array
function printGroundItems {
    param($groundItems)
    foreach ($item in $groundItems) {
        if (ifInViewport -printable $item -origX $origX -origY $origY) {
            printItem -printable $item   -origX $origX -origY $origY
        }
    }
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
    printGroundItems -groundItems $groundItems
    
    printItem -printable $player -origX $origX -origY $origY
}

# printing HUD and all of it's elements
function PrintHud {
    param ($health, $stamina)
    [System.Console]::SetCursorPosition(9, 1)
    Write-Host "HP: ◼◼◼◼◼◼◼◼" -ForegroundColor Red

    [System.Console]::SetCursorPosition(9, 3)
    Write-Host "x:$($player.x), y:$($player.y)"
}

function dropItem {
    param ($item)

    $script:groundItems += [PSCustomObject]@{
        print       = $item.print
        name        = $item.name
        description = $item.description
        color       = $item.color
        x           = $player.x
        y           = $player.y
    }
}

function itemInterraction {
    param (
        [PSCustomObject]$item
    )
    Clear-Host
    Write-Host "(Enter - return; d - drop)"
    Write-Host "| $($item.print) $($item.name)" -ForegroundColor $item.color
    Write-Host " $($item.description)"
    $pressedButton = [Console]::ReadKey($true)
    switch ($pressedButton.Key) {
        'e' { return }
        'd' {
            dropItem -item $item
            $list = [System.Collections.ArrayList]$script:playerInventory
            $list.Remove($item) | Out-Null
            $script:playerInventory = $list.ToArray()
            return
        }
    }
}

# function to handle the inventory
function inventory {
    param()
    $selectedItem = 0
    while ($true) {
        Clear-Host
        Write-Host "Inventory (e - Exit; w,s - move; Enter - Select)"
        $inventoryY = 2
        for ($i = 0; $i -lt $script:playerInventory.Count; $i++) {
            [System.Console]::SetCursorPosition(1, $inventoryY)
            Write-Host "|" -NoNewline
            if ($i -eq $selectedItem) {
                Write-Host "$($script:playerInventory[$i].print) $($script:playerInventory[$i].name)" -ForegroundColor $script:playerInventory[$i].color -BackgroundColor White
            }
            else {
                Write-Host "$($script:playerInventory[$i].print) $($script:playerInventory[$i].name)" -ForegroundColor $script:playerInventory[$i].color
            }
            $inventoryY++
        }
        
        $pressedButton = [Console]::ReadKey($true)
        switch ($pressedButton.Key) {
            'w' { if ($selectedItem -gt 0) { $selectedItem-- } }
            's' { if ($selectedItem -lt $script:playerInventory.Count - 1) { $selectedItem++ } }
            'Enter' {
                itemInterraction -item $script:playerInventory[$selectedItem]
            }
            'e' { return }
        }
    }
}

# calling world generation
$world = GenerateWorld -world $world

# Main game loop
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
        'e' { inventory } # inventory
        'f' {  } # interractions
        'p' { Clear-Host; return }
        Default {}
    }
}