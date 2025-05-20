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
    param(
        [string]$direcrion,
        [array]$impassables,
        [int]$playerx,
        [int]$playery,
        [int]$locationH,
        [int]$locationW
    )

    switch ($direcrion) {
        'up' {
            $tileX = $playerx
            $tileY = $playery - 1
            if ($impassables | Where-Object { $_.x -eq $tileX -and $_.y -eq $tileY }) {
                return
            }
            if ($playery -gt 0) {
                $script:player.y--
            } 
        }
        'down' {
            $tileX = $script:player.x
            $tileY = $script:player.y + 1
            if ($impassables | Where-Object { $_.x -eq $tileX -and $_.y -eq $tileY }) {
                return
            }
            if ($script:player.y -lt $locationH - 1) {
                $script:player.y++
            }
        }
        'left' {
            $tileX = $script:player.x - 1
            $tileY = $script:player.y
            if ($impassables | Where-Object { $_.x -eq $tileX -and $_.y -eq $tileY }) {
                return
            }
            if ($script:player.x -gt 0 ) {
                $script:player.x--
            }
        }
        'right' {
            $tileX = $script:player.x + 1
            $tileY = $script:player.y
            if ($impassables | Where-Object { $_.x -eq $tileX -and $_.y -eq $tileY }) {
                return
            }
            if ($script:player.x -lt $locationW - 1) {
                $script:player.x++
            }
        }
    }
}