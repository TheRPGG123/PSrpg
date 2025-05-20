# a script that returns an array of all impassable terrain on a certain map, making the movement collision checking faster
function calculateImpassables {
    param (
        [array]$map,
        [string]$impassableTerrain
    )
    $impassableTiles = @()
    foreach ($tile in $map) {
        if ($tile.print -match "$impassableTerrain") {
            $impassableTiles += [PSCustomObject]@{
                print = $tile.print
                info  = $tile.info
                color = $tile.color
                x     = $tile.x
                y     = $tile.y
            }
        }
    }

    return $impassableTiles
}

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