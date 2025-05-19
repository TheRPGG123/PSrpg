
## setting up encoding and some console quality of life
chcp 65001
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()
[Console]::InputEncoding = [Text.UTF8Encoding]::new()
[Console]::CursorVisible = $false

. ".\modules\terrainGeneration.ps1"
. ".\modules\locationGenerator.ps1"
. ".\modules\rendering.ps1"
. ".\modules\misc.ps1"
. ".\modules\playerInterractions.ps1"

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

$script:worldLocations = @(
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

$script:town = @()
$script:impassableTown = @()

## functions:
# Function that draws, listens for input and executes the world map functionality
function worldMapMovement {
    Clear-Host
    
    while ($true) {
        Clear-Host
        PrintMap -world $script:world
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
                        $script:impassablWorld = calculateImpassables -map $script:world

                        
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
                    0 { worldParameters; worldMapMovement }
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