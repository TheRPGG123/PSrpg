chcp 65001
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()
[Console]::InputEncoding = [Text.UTF8Encoding]::new()
[Console]::CursorVisible = $false
Clear-Host

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

    $houseTiles = @()
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
                    $char = '█' # wall
                    $color = 'darkYellow'
                    $info = 'wooden wall'
                }
            }
            else {
                $char = '.'       # floor
                $color = 'DarkYellow'
                $info = 'floor'
            }

            $houseTiles += [PSCustomObject]@{
                print = $char
                color = $color
                info  = 'house'
                x     = $x
                y     = $y
            }
        }
    }
    return $houseTiles
}

function generateStartingTown {
    $town = @()

    $grassTexture = ",.;:"
    # filling the location with grass and adding random trees in the mix
    for ($i = 0; $i -lt $locationWidth; $i++) {
        for ($j = 0; $j -lt $locationHeight; $j++) {
            $t = Get-Random -Maximum 12
            if ($t -eq 6) {
                $town += [PSCustomObject]@{
                    print = '^'
                    info  = 'A fir tree'
                    color = 'darkGreen'
                    x     = $i
                    y     = $j
                }
            }
            elseif ($t -eq 5) {
                $town += [PSCustomObject]@{
                    print = ':'
                    info  = 'pebbles'
                    color = 'gray'
                    x     = $i
                    y     = $j
                }
            }
            else {
                $town += [PSCustomObject]@{
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
        $town += [PSCustomObject]@{
            print = '#';
            info  = 'paved road';
            color = 'gray';
            x     = $i;
            y     = $roadYoffset
        }
    }

    [int]$roadXoffset = $locationWidth / 2
    for ($i = 0; $i -lt $locationHeight; $i++) {
        $town += [PSCustomObject]@{
            print = '#';
            info  = 'paved road';
            color = 'gray';
            x     = $roadXoffset ;   
            y     = $i
        }
    }

    # draw a well in the center
    $town += [PSCustomObject]@{
        print = 'O'
        info  = 'well for getting water'
        color = 'darkGray'
        x     = $roadXoffset    
        y     = $roadYoffset
    }
    # place down a few houses in the respective quadrants (1, 2, 3 and 4)
    $halfW = [int]($locationWidth / 2)
    $halfH = [int]($locationHeight / 2)
        
    for ($i = 0; $i -lt $numberOfHouses; $i++) {
        
        $w = Get-Random -Minimum 5 -Maximum 9
        $h = Get-Random -Minimum 5 -Maximum 9

        switch ($i) {
            0 {
                # NW
                $xMin = 2
                $xMax = $halfW - $w - 1
                $yMin = 2
                $yMax = $halfH - $h - 1
                $doors = 'south', 'east'
            }
            1 {
                # NE
                $xMin = $halfW
                $xMax = $locationWidth - $w - 1
                $yMin = 2
                $yMax = $halfH - $h - 1
                $doors = 'south', 'west'
            }
            2 {
                # SW
                $xMin = 2
                $xMax = $halfW - $w - 1
                $yMin = $halfH
                $yMax = $locationHeight - $h - 1
                $doors = 'north', 'east'
            }
            3 {
                # SE
                $xMin = $halfW
                $xMax = $locationWidth - $w - 1
                $yMin = $halfH
                $yMax = $locationHeight - $h - 1
                $doors = 'north', 'west'
            }
        }

        # clamp so Min ≤ Max
        if ($xMax -lt $xMin) { $xMax = $xMin }
        if ($yMax -lt $yMin) { $yMax = $yMin }

        # now pick coords safely
        $x = Get-Random -Minimum $xMin -Maximum $xMax
        $y = Get-Random -Minimum $yMin -Maximum $yMax
        $side = $doors | Get-Random

        $town += GenerateHouse `
            -originX  $x `
            -originY  $y `
            -width    $w `
            -height   $h `
            -doorSide $side
    }

    return $town
}