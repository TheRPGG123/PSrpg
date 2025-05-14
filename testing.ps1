
## setting up encoding and some console quality of life
chcp 65001
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()
[Console]::InputEncoding = [Text.UTF8Encoding]::new()
[Console]::CursorVisible = $false

$script:devmode = $false

Clear-Host

## setup of initial important parameters
$titlecard = @"
______  _________________ _____ 
| ___ \/  ___| ___ \ ___ \  __ \
| |_/ /\ '--.| |_/ / |_/ / |  \/
|  __/  '--. \    /|  __/| | __ 
| |    /\__/ / |\ \| |   | |_\ \
\_|    \____/\_| \_\_|    \____/
                                
                                
"@
$mainMenuOptions = @(
    "New game"
    "Continue game"
    "Credits"
    "Quit"
)

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
$worldWidth = 25
$worldHeight = 25
$worldSeed = Get-Random -Maximum 100
$worldScale = 0.2
$worldOctaves = 4
$worldPersistance = 0.2
$worldWater = -0.2
$worldPlains = 0.2
$worldForests = 0.7
$world = @()

# script:player object
$script:player = [PSCustomObject]@{
    print    = '@'
    class    = 'none'
    color    = 'white'
    x        = [int]($worldWidth / 2)  
    y        = [int]($worldHeight / 2)
    location = 'world'
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
        x           = 12
        y           = 12
        location    = 'town'
    },
    [PSCustomObject]@{
        print       = '/'
        name        = 'Iron Sword'
        description = '+5 Attack, reliable blade'
        color       = 'Gray'
        x           = 13
        y           = 13
        location    = 'town'
    }
)

$script:locations = @(
    [PSCustomObject]@{
        print          = 'T'
        name           = 'town name'
        description    = 'Short description of a town'
        color          = 'yellow'
        x              = 12
        y              = 12
        location       = 'world'
        whenInLocation = 'town'
    }
)

$script:world = @()
$script:impassablWorld = @()

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

# making a map with fractal Brownian motion
function GenerateWorld {
    param(
        [array]  $world = @(),
        [int]    $width = 100,
        [int]    $height = 100,
        [int]    $seed = (Get-Random),
        [double] $scale = 0.3,
        [int]    $octaves = 4,
        [double] $persistence = 0.5,
        [double] $waterLevel = -0.3,
        [double] $plainsLevel = 0.0,
        [double] $forestLevel = 0.5
    )

    # derive two random offsets from seed
    $rnd = [Random]::new($seed) 
    $offX = $rnd.Next(0, 100000)
    $offY = $rnd.Next(0, 100000)

    [System.Console]::SetCursorPosition(2, 2)
    Write-Host "Generating world..."

    # raw int hash → [-1..1], now shifted
    function RawNoise {
        param([int]$x, [int]$y)
        # apply our offsets
        [bigint]$xi = $x + $offX
        [bigint]$yi = $y + $offY
        # the old hash, but on (xi, yi)
        [bigint]$n = $xi + $yi * 57
        $n = ($n -shr 13) -bxor $n
        [bigint]$t = $n * ($n * $n * 15731) + 789221
        $t = $t -band 0x7FFFFFFF
        return 1.0 - ([double]$t / 1073741824.0)
    }

    function Lerp($a, $b, $t) { $a + ($b - $a) * $t }

    function Smooth($x, $y) {
        $ix = [math]::Floor($x); $iy = [math]::Floor($y)
        $fx = $x - $ix; $fy = $y - $iy
        $v1 = RawNoise $ix    $iy
        $v2 = RawNoise ($ix + 1)$iy
        $v3 = RawNoise $ix    ($iy + 1)
        $v4 = RawNoise ($ix + 1)($iy + 1)
        $i1 = Lerp $v1 $v2 $fx; $i2 = Lerp $v3 $v4 $fx
        Lerp $i1 $i2 $fy
    }

    function FBM($x, $y) {
        $total = 0; $freq = 1; $amp = 1; $max = 0
        for ($o = 0; $o -lt $octaves; $o++) {
            $total += (Smooth ($x * $freq) ($y * $freq)) * $amp
            $max += $amp
            $amp *= $persistence
            $freq *= 2
        }
        return $total / $max
    }

    # build the world
    for ($x = 0; $x -lt $width; $x++) {
        for ($y = 0; $y -lt $height; $y++) {
            $n = FBM ($x * $scale) ($y * $scale)
            if ($n -lt $waterLevel ) { $c = '~'; $col = 'DarkBlue' }
            elseif ($n -lt $plainsLevel) { $c = '.'; $col = 'DarkGreen' }
            elseif ($n -lt $forestLevel) { $c = ','; $col = 'Green' }
            else { $c = '^'; $col = 'Gray' }

            $world += [PSCustomObject]@{
                print = $c
                info  = ''
                color = $col
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
        if ($item.location -eq $script:player.location -and (ifInViewport -printable $item -origX $origX -origY $origY)) {
            printItem -printable $item   -origX $origX -origY $origY
        }
    }
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
    param($world)
    Clear-Host
    Write-Host $gameWindow

    # calculate camera origin
    $halfW = [math]::Floor($viewPortWidth / 2)
    $halfH = [math]::Floor($viewPortHeight / 2)
    $origX = [math]::Max(0, [math]::Min($script:player.x - $halfW, $worldWidth - $viewPortWidth))
    $origY = [math]::Max(0, [math]::Min($script:player.y - $halfH, $worldHeight - $viewPortHeight))

    # draw all visible tiles
    foreach ($t in $world) {
        if ($t.x -ge $origX -and $t.x -lt $origX + $viewPortWidth -and $t.y -ge $origY -and $t.y -lt $origY + $viewPortHeight) {
            printItem -printable $t -origX $origX -origY $origY
        }
    }

    # draw the item and script:player via the same helper 
    printGroundItems -groundItems $script:groundItems

    printLocations -locations $script:locations
    
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

# dropping items from inventory to ground
function dropItem {
    param ($item)

    $script:groundItems += [PSCustomObject]@{
        print       = $item.print
        name        = $item.name
        description = $item.description
        color       = $item.color
        x           = $script:player.x
        y           = $script:player.y
    }
}

# interraction with items in inventory
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

# function where all moving and moving checks are done
function moving {
    param([string]$direcrion)

    switch ($direcrion) {
        'up' {
            $tileX = $script:player.x
            $tileY = $script:player.y - 1
            $tile = $script:impassablWorld | Where-Object { $_.x -eq $tileX -and $_.y -eq $tileY }
            if ($tile.print -match '[~^]') { return }
            if ($script:player.y -gt 0) {
                $script:player.y--
            } 
        }
        'down' {
            $tileX = $script:player.x
            $tileY = $script:player.y + 1
            $tile = $script:impassablWorld | Where-Object { $_.x -eq $tileX -and $_.y -eq $tileY }
            if ($tile.print -match '[~^]') { return }
            if ($script:player.y -lt $worldHeight - 1) {
                $script:player.y++
            }
        }
        'left' {
            $tileX = $script:player.x - 1
            $tileY = $script:player.y
            $tile = $script:impassablWorld | Where-Object { $_.x -eq $tileX -and $_.y -eq $tileY }
            if ($tile.print -match '[~^]') { return }
            if ($script:player.x -gt 0 ) {
                $script:player.x--
            }
        }
        'right' {
            $tileX = $script:player.x + 1
            $tileY = $script:player.y
            $tile = $script:impassablWorld | Where-Object { $_.x -eq $tileX -and $_.y -eq $tileY }
            if ($tile.print -match '[~^]') { return }
            if ($script:player.x -lt $worldWidth - 1) {
                $script:player.x++
            }
        }
    }
}

# Function that draws, listens for input and executes the world map functionality
function gamePlay {
    Clear-Host
    # calling world generation with all the parameters 
    # here for now, Make a screen later for more varied world generation
    $script:world = GenerateWorld -world $world -worldWidth $worldWidth -worldHeight $worldHeight `
        -seed $worldSeed -scale $worldScale -octaves $worldOctaves -persistence $worldPersistance `
        -waterLevel $worldWater -plainsLevel $worldPlains -forestLevel $worldForests
    foreach ($tile in $world) {
        if ($tile.print -match '[~^]') {
            $script:impassablWorld += [PSCustomObject]@{
                print = $tile.print
                info  = $tile.info
                color = $tile.color
                x     = $tile.x
                y     = $tile.y
            }
        }
    }

    while ($true) {
        Clear-Host
        PrintMap -world $world
        PrintHud -health 2 -stamina 2
        $pressedButton = [Console]::ReadKey($true)
        switch ($pressedButton.KeyChar) {
            'w' { moving -direcrion 'up' }
            's' { moving -direcrion 'down' }
            'a' { moving -direcrion 'left' }
            'd' { moving -direcrion 'right' }
            'e' { inventory } # inventory
            'f' {  } # interractions
            'p' { Clear-Host; return }
            Default {}
        }
    }
    # Main game loop
}

# main menu with multiple choices
function mainMenu {
    $selectedMainMenuOption = 0
    # immediatly going to the game if devmode enabled
    if ($script:devmode) {
        gamePlay
    }
    while ($true) {
        Clear-Host
        Write-Host $titlecard -ForegroundColor DarkCyan
        for ($i = 0; $i -le $mainMenuOptions.Length - 1; $i++) {
            if ($selectedMainMenuOption -eq $i) {
                Write-Host " " -NoNewline
                Write-Host "->" -ForegroundColor Cyan -BackgroundColor DarkGray -NoNewline
                Write-Host " $($mainMenuOptions[$i])" -ForegroundColor Cyan
            }
            else {
                Write-Host " -> $($mainMenuOptions[$i])" -ForegroundColor Cyan
            }
        }
        $pressedButton = [Console]::ReadKey($true)
        switch ($pressedButton.Key) {
            'w' { if ($selectedMainMenuOption -gt 0) { $selectedMainMenuOption-- } }
            's' { if ($selectedMainMenuOption -lt $mainMenuOptions.Length - 1) { $selectedMainMenuOption++ } }
            'Enter' {
                switch ($selectedMainMenuOption) {
                    0 { gamePlay }
                    1 {}
                    2 {}
                    3 { Clear-Host; return }
                }
            }
            Default {}
        }
    }
}

mainMenu