# a script that returns an array of all impassable terrain on a certain map, making the movement collision checking faster
function calculateImpassables {
    param ($map)
    $impassableTiles = @()
    foreach ($tile in $map) {
        if ($tile.print -match '[~^]') {
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