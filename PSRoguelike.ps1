
## setting up encoding and some console quality of life
chcp 65001
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()
[Console]::InputEncoding = [Text.UTF8Encoding]::new()
[Console]::CursorVisible = $false

. ".\modules\terrainGeneration.ps1"
. ".\modules\locationGenerator.ps1"
. ".\modules\rendering.ps1"
. ".\modules\playerInterractions.ps1"

$script:devmode = $false

#Clear-Host

## setup of initial important parameters
$titlecard = @"
______  _________________ _____ 
| ___ \/  ___| ___ \ ___ \  __ \
| |_/ /\ '--.| |_/ / |_/ / |  \/
|  __/  '--. \    /|  __/| | __ 
| |    /\__/ / |\ \| |   | |_\ \
\_|    \____/\_| \_\_|    \____/
                                
                                
"@

# Default parameters for a world
$script:worldParameters = [PSCustomObject]@{
    width        = 25
    height       = 25
    seed         = Get-Random -Maximum 1000
    scale        = 0.2
    octaves      = 4
    persistance  = 0.2
    waterCutoff  = -0.2
    plainsCutoff = 0.2
    forestCutoff = 0.7
}

# script:player object
$script:player = [PSCustomObject]@{
    print    = '@'
    class    = 'none'
    color    = 'white'
    x        = [int]($script:worldParameters.width / 2)  
    y        = [int]($script:worldParameters.height / 2)
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

$script:worldLocations = @()

$script:world = @()
$script:impassablWorld = @()
$script:playerWorldLocationX = 12
$script:playerWorldLocationY = 12

## functions:
# Function that draws, listens for input and executes the world map functionality
function locationMovement {
    param($locName)
    $loc = $script:worldLocations | Where-Object { $_.name -eq $locName }

    $script:player.x = $loc.playerX
    $script:player.y = $loc.playerY

    while ($true) {
        Clear-Host

        printMap -location $loc

        $key = [Console]::ReadKey($true).Key
        switch ($key) {
            'w' {
                moving -direcrion 'up' -impassables $loc.impassables -playerx $script:player.x `
                    -playery $script:player.y -locationH $loc.height -locationW $loc.width 
            }
            's' {
                moving -direcrion 'down' -impassables $loc.impassables -playerx $script:player.x `
                    -playery $script:player.y -locationH $loc.height -locationW $loc.width 
            }
            'a' {
                moving -direcrion 'left' -impassables $loc.impassables -playerx $script:player.x `
                    -playery $script:player.y -locationH $loc.height -locationW $loc.width 
            }
            'd' {
                moving -direcrion 'right' -impassables $loc.impassables -playerx $script:player.x `
                    -playery $script:player.y -locationH $loc.height -locationW $loc.width 
            }

            'f' {
                # Exit back to world whenever F is pressed inside location
                return
            }
            'e' {
                inventory
            }
            'p' {
                # also back to world
                return
            }
        }
    }
}

function worldMapMovement {
    # Main game loop
    while ($true) {
        Clear-Host
        PrintWorld -map $script:world
        $pressedButton = [Console]::ReadKey($true)
        switch ($pressedButton.KeyChar) {
            'w' {
                moving -direcrion 'up' -impassables $script:impassablWorld -playerx $script:player.x -playery $script:player.y `
                    -locationH $script:worldParameters.height -locationW $script:worldParameters.width 
            }
            's' {
                moving -direcrion 'down' -impassables $script:impassablWorld -playerx $script:player.x -playery $script:player.y `
                    -locationH $script:worldParameters.height -locationW $script:worldParameters.width 
            }
            'a' {
                moving -direcrion 'left' -impassables $script:impassablWorld -playerx $script:player.x -playery $script:player.y `
                    -locationH $script:worldParameters.height -locationW $script:worldParameters.width 
            }
            'd' {
                moving -direcrion 'right' -impassables $script:impassablWorld -playerx $script:player.x -playery $script:player.y `
                    -locationH $script:worldParameters.height -locationW $script:worldParameters.width 
            }
            'e' { inventory } # inventory
            'f' { 
                $loc = $script:worldLocations |  Where-Object { $_.x -eq $script:player.x -and $_.y -eq $script:player.y }
                if ($loc) {
                    $script:playerWorldLocationX = $script:player.x
                    $script:playerWorldLocationY = $script:player.y
                    locationMovement $loc.name
                    $script:player.x = $script:playerWorldLocationX
                    $script:player.y = $script:playerWorldLocationY
                }
            }  
            'p' {  }
            Default {}
        }
    }
}

function worldParameters {
    $worldParameterOptions = @(
        "Seed"
        "World scale"
        "World octaves"
        "World persistance"
        "Water cutoff"
        "Plains cutoff"
        "Forest cutoff"
        "Generate!"
    )
    $selectedWorldParameter = 0
    while ($true) {
        Clear-Host
        Write-Host "World generation:"
        Write-Host
        for ($i = 0; $i -lt $worldParameterOptions.Length; $i++) {
            if ($selectedWorldParameter -eq $i) {
                Write-Host " " -NoNewline
                Write-Host "->" -NoNewline -ForegroundColor Cyan -BackgroundColor DarkGray
                Write-Host " $($worldParameterOptions[$i])" -ForegroundColor Cyan
            }
            else {
                Write-Host " > $($worldParameterOptions[$i])" -ForegroundColor Cyan
            }
        }
    
        $pressedButton = [Console]::ReadKey($true)
        switch ($pressedButton.Key) {
            'w' { if ($selectedWorldParameter -gt 0) { $selectedWorldParameter-- } }
            's' { if ($selectedWorldParameter -lt $worldParameterOptions.Length - 1) { $selectedWorldParameter++ } }
            'Enter' {
                switch ($selectedWorldParameter) {
                    0 {
                        Clear-Host
                        Write-Host "Enter the seed (-99999 to 99999)"
                        Write-Host "Either enter a unique one or leave it blank for a random seed"
                        Write-Host
                        $script:worldParameters.seed = Read-Host " > "
                    }
                    1 {
                        Clear-Host
                        Write-Host "Enter world scale (0.01 to 1)"
                        Write-Host "World scale influences how big the biomes are. Bigger values create smaller biomes"
                        Write-Host
                        $script:worldParameters.scale = Read-Host " > "
                    }
                    2 {
                        Clear-Host
                        Write-Host "Enter the number of octaves (1 to 10)"
                        Write-Host "Number of octaves influences how many layers of noise are stacked on each other"
                        Write-Host "Higher number will have very long generation times" -ForegroundColor Red
                        Write-Host
                        $script:worldParameters.octaves = Read-Host " > "
                    }
                    3 {
                        Clear-Host
                        Write-Host "Enter world persistance (0.01 to 1)"
                        Write-Host "Persistance influences how much influence the suceeding octaves have on the first one."
                        Write-Host
                        $script:worldParameters.persistance = Read-Host " > "
                    }
                    4 {
                        Clear-Host
                        Write-Host "Enter water cutoff (-1 to 1)"
                        Write-Host "Tells the script to what `"elevation`" the water will be set"
                        Write-Host
                        $script:worldParameters.waterCutoff = Read-Host " > "
                    }
                    5 {
                        Clear-Host
                        Write-Host "Enter plains cutoff (-1 to 1)"
                        Write-Host "Tells the script to what `"elevation`" the plains will be set"
                        Write-Host
                        $script:worldParameters.plainsCutoff = Read-Host " > "
                    }
                    6 {
                        Clear-Host
                        Write-Host "Enter forest cutoff (-1 to 1)"
                        Write-Host "Tells the script to what `"elevation`" the forest will be set"
                        Write-Host
                        $script:worldParameters.forestCutoff = Read-Host " > "
                    }
                    7 {
                        Clear-Host
                        $script:world = GenerateWorld `
                            -world $script:world `
                            -worldWidth $script:worldParameters.width `
                            -worldHeight $script:worldParameters.height `
                            -seed $script:worldParameters.seed `
                            -scale $script:worldParameters.scale `
                            -octaves $script:worldParameters.octaves `
                            -persistence $script:worldParameters.persistance `
                            -waterLevel $script:worldParameters.waterCutoff `
                            -plainsLevel $script:worldParameters.plainsCutoff `
                            -forestLevel $script:worldParameters.forestCutoff 
                        $script:impassablWorld = calculateImpassables -map $script:world -impassableTerrain "^~"
                        return
                    }
                }
            }
            Default {}
        }
    }
}

# main menu with multiple choices
function mainMenu {
    $mainMenuOptions = @(
        "New game"
        "Continue game"
        "Credits"
        "Quit"
    )
    $selectedMainMenuOption = 0
    # immediatly going to the game if devmode enabled
    if ($script:devmode) {
        worldMapMovement
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
                    0 { 
                        worldParameters
                        $script:worldLocations = generateLocations
                        worldMapMovement
                    }
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