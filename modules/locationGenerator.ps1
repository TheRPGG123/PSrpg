function generateStartingTown {
    $town = @()
    $grassTexture = ",.;:"

    for ($i = 0; $i -lt 25; $i++) {
        for ($j = 0; $j -lt 25; $j++) {
            $town += [PSCustomObject]@{
                print = $grassTexture[$(Get-Random -Maximum 3)]
                info  = ''
                color = 'green'
                x     = $i
                y     = $j
            }
        }
    }
}