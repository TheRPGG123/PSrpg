$script:town = @()

$locationHeight = 25
$locationWidth = 25

$numberOfHouses = 4

function GenerateHouse {
    param(
        [int]   $originX,
        [int]   $originY,
        [int]   $width, # full outer width, ≥ 3
        [int]   $height, # full outer height, ≥ 3
        [string]$doorSide = 'south'  # north, south, east or west
    )
    # pick door position centered on the chosen wall
    switch ($doorSide) {
        'north' { $doorX = $originX + [math]::Floor($width / 2); $doorY = $originY }
        'south' { $doorX = $originX + [math]::Floor($width / 2); $doorY = $originY + $height - 1 }
        'west' { $doorX = $originX; $doorY = $originY + [math]::Floor($height / 2) }
        'east' { $doorX = $originX + $width - 1; $doorY = $originY + [math]::Floor($height / 2) }
    }
    for ($dx = 0; $dx -lt $width; $dx++) {
        for ($dy = 0; $dy -lt $height; $dy++) {
            $x = $originX + $dx
            $y = $originY + $dy

            # border?
            if ($dx -eq 0 -or $dx -eq $width - 1 -or $dy -eq 0 -or $dy -eq $height - 1) {
                # carve out the door
                if ($x -eq $doorX -and $y -eq $doorY) {
                    $char = '+'   # doorway
                    $color = 'darkYellow'
                    $info = 'doorway'
                }
                else {
                    $char = '#'   # '█' wall
                    $color = 'darkYellow'
                    $info = 'wooden wall'
                }
            }
            else {
                $char = '.'       # floor
                $color = 'DarkYellow'
                $info = 'floor'
            }

            $script:town += [PSCustomObject]@{
                print = $char
                color = $color
                info  = 'house'
                x     = $x
                y     = $y
            }
        }
    }
}

function generateStartingTown {
    $grassTexture = ",.;:"
    # filling the location with grass and adding random trees in the mix
    for ($i = 0; $i -lt $locationWidth; $i++) {
        for ($j = 0; $j -lt $locationHeight; $j++) {
            $t = Get-Random -Maximum 12
            if ($t -eq 6) {
                $script:town += [PSCustomObject]@{
                    print = '^'
                    info  = 'A fir tree'
                    color = 'darkGreen'
                    x     = $i
                    y     = $j
                }
            }
            elseif ($t -eq 5) {
                $script:town += [PSCustomObject]@{
                    print = '^' #'┐' here for when you run the main script
                    info  = 'A dried up tree'
                    color = 'darkRed'
                    x     = $i
                    y     = $j
                }
            }
            else {
                $script:town += [PSCustomObject]@{
                    print = $grassTexture[$(Get-Random -Maximum 3)]
                    info  = 'a tile of green grass'
                    color = 'green'
                    x     = $i
                    y     = $j
                }
            }
        }
    }
    # draw roads leading in 4 directions
    [int]$roadYoffset = $locationHeight / 2
    for ($i = 0; $i -lt $locationWidth; $i++) {
        $script:town += [PSCustomObject]@{
            print = '#' #'░' here for when you run the main script
            info  = 'paved road'
            color = 'gray'
            x     = $i
            y     = $roadYoffset
        }
    }

    [int]$roadXoffset = $locationWidth / 2
    for ($i = 0; $i -lt $locationHeight; $i++) {
        $script:town += [PSCustomObject]@{
            print = '#' #'░' here for when you run the main script
            info  = 'paved road'
            color = 'gray'
            x     = $roadXoffset    
            y     = $i
        }
    }

    # draw a well in the center
    $script:town += [PSCustomObject]@{
        print = 'O' #'░' here for when you run the main script
        info  = 'paved road'
        color = 'darkGray'
        x     = $roadXoffset    
        y     = $roadYoffset
    }
    # place down a few houses in the respective quadrants (1, 2, 3 and 4)
    for ($i = 0; $i -lt $numberOfHouses; $i++) {
        switch ($i) {
            0 {
                # quadrant NW
                $w = Get-Random -Minimum 5 -Maximum 9
                $h = Get-Random -Minimum 5 -Maximum 9
                $x = Get-Random -Minimum 2 -Maximum ($locationWidth / 2 - $w)
                $y = Get-Random -Minimum 2 -Maximum ($locationHeight / 2 - $h)
                $side = @('south', 'east') | Get-Random
                GenerateHouse -originX $x -originY $y `
                    -width $w -height $h -doorSide $side
            }
            1 {
                # quadrant NE
                $w = Get-Random -Minimum 5 -Maximum 9
                $h = Get-Random -Minimum 5 -Maximum 9
                $x = Get-Random -Minimum ($locationWidth / 2) -Maximum ($locationWidth - ($w + 1))
                $y = Get-Random -Minimum 2 -Maximum ($locationHeight / 2 - $h)
                $side = @('south', 'west') | Get-Random
                GenerateHouse -originX $x -originY $y `
                    -width $w -height $h -doorSide $side
            }
            2 {
                #quadrant SW
                $w = Get-Random -Minimum 5 -Maximum 9
                $h = Get-Random -Minimum 5 -Maximum 9
                $x = Get-Random -Minimum 2 -Maximum ($locationWidth / 2 - $w)
                $y = Get-Random -Minimum ($locationHeight / 2) -Maximum ($locationHeight - ($h + 1))
                $side = @('north', 'east') | Get-Random
                GenerateHouse -originX $x -originY $y `
                    -width $w -height $h -doorSide $side
            }
            3 {
                # quadrant SE
                $w = Get-Random -Minimum 5 -Maximum 9
                $h = Get-Random -Minimum 5 -Maximum 9
                $x = Get-Random -Minimum ($locationWidth / 2) -Maximum ($locationWidth - ($w + 1))
                $y = Get-Random -Minimum ($locationHeight / 2) -Maximum ($locationHeight - ($h + 1))
                $side = @('north', 'west') | Get-Random
                GenerateHouse -originX $x -originY $y `
                    -width $w -height $h -doorSide $side
            }
            Default {}
        }
    }
}

function testPrintMap {
    param ($map)
    foreach ($tile in $map) {
        [System.Console]::SetCursorPosition($tile.x, $tile.y)
        Write-Host $tile.print -ForegroundColor $tile.color
    }
}
generateStartingTown

testPrintMap -map $script:town
Read-Host