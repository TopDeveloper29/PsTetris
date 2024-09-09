# Add necessary assemblies for key handling and UI
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

class Size {
    [int]$X
    [int]$Y

    Size([int]$x, [int]$y) {
        $this.X = $x
        $this.Y = $y
    }
}

class Location {
    [int]$X
    [int]$Y

    Location([int]$x, [int]$y) {
        $this.X = $x
        $this.Y = $y
    }
}

class Block {
    [Size]$Size
    [ConsoleColor]$Color
    [int]$X
    [int]$Y = 0
    [Map]$Map
    [bool]$StuckAtTop = $false

    Block([Map]$Map) {
        $this.Map = $Map
        $this.Size = [Size]::new((Get-Random -Minimum 1 -Maximum 4), (Get-Random -Minimum 1 -Maximum 2))
        $this.X = (Get-Random -Minimum 0 -Maximum ($Map.Size.X - $this.Size.X))
        $colors = [Enum]::GetValues([ConsoleColor]) | Where-Object { $_ -notin ([ConsoleColor]::White, [ConsoleColor]::Black, [ConsoleColor]::Gray) }
        $this.Color = Get-Random -InputObject $colors
    }

    [void]Reverse() {
        [int]$NewY = ($this.Size.X / 2)
        [int]$NewX = ($this.Size.Y * 2)
        if($NewY -gt 0 -and $NewX -gt 0)
        {
            $this.Size = New-Object Size($NewX, $NewY);
        }
        else{
            $this.Size = New-Object Size($this.Size.Y, $this.Size.X);
        }
        
    }
    

    [Location[]] GetAllLocation() {
        [Location[]]$AllLocation = @()
        for ([int]$OffsetY = $this.Y; $OffsetY -lt ($this.Y + $this.Size.Y); $OffsetY++) {
            for ([int]$OffsetX = $this.X; $OffsetX -lt ($this.X + $this.Size.X); $OffsetX++) {
                $AllLocation += [Location]::new($OffsetX, $OffsetY)
            }
        }
        return $AllLocation
    }

    [bool] IsAt([int]$X, [int]$Y) {
        foreach ($Location in $this.GetAllLocation()) {
            if ($Location.X -eq $X -and $Location.Y -eq $Y) {
                return $true
            }
        }
        return $false
    }

    [bool] IsColiding() {
        $Coliding = $false
        foreach ($Location in $this.GetAllLocation())
        {
            if ($Location.Y -ge $this.Map.Size.Y) {
                $Coliding = $true
                break
            }
            foreach ($Block in $this.Map.Blocks) {
                if ($Block -ne $this) {
                    foreach ($BlockLocation in $Block.GetAllLocation()) {
                        if ($BlockLocation.X -eq $Location.X -and $BlockLocation.Y-1 -eq $Location.Y) {
                            $Coliding = $true
                            if ($BlockLocation.Y - 1 -lt 2) {
                                $this.StuckAtTop = $true
                            }
                            break
                        }
                    }
                }
            }
        }
        return $Coliding
    }
}
class Map {
    [Size]$Size = [Size]::new(8, 10)
    hidden [string]$Texture = "█"
    [System.Collections.Generic.List[Block]]$Blocks
    [Block]$CurrentBlock
    [int]$Score = 0
    [int]$Best = 0

    Map() {
        $this.Blocks = [System.Collections.Generic.List[Block]]::new()
    }

    [void] Update() {
        Clear-Host
        [int]$X = 0
        [int]$Y = 0

        if(-not (Test-Path -Path "HKCU:\Software\PsTetris"))
        {
            New-Item -Path "HKCU:\Software\PsTetris"
            Set-ItemProperty -Path "HKCU:\Software\PsTetris" -Name "Best" -Value 0
        }

        $this.Best = Get-ItemPropertyValue -Path "HKCU:\Software\PsTetris" -Name "Best";

        Write-Host "Score : " -ForegroundColor Blue -NoNewline
        Write-Host $this.Score -ForegroundColor Blue
        Write-Host "Best  : " -ForegroundColor Blue -NoNewline
        Write-Host $this.Best -ForegroundColor Blue
        Write-Host ""

        while ($Y -lt $this.Size.Y) {
            $X = 0
            [bool]$LineFull = $true

            while ($X -lt $this.Size.X) {
                [Block]$Match = $null
                foreach ($block in $this.Blocks) {
                    if ($block.IsAt($X, $Y)) {
                        $Match = $block
                        break
                    }
                }

                if ($null -ne $Match) {
                    Write-Host $this.Texture -NoNewline -ForegroundColor $Match.Color
                } else {
                    $LineFull = $false
                    Write-Host $this.Texture -NoNewline -ForegroundColor White
                }
                $X++
            }

            if ($LineFull) {
                $this.Score++
                if ($this.Score -gt $this.Best) {
                    Set-ItemProperty -Path "HKCU:\Software\PsTetris" -Name "Best" -Value $this.Score
                }
            
                # Move blocks down if a line is full

                $this.Blocks | Where-Object { ($_.Y + $_.Size.Y - 2) -eq $Y } | ForEach-Object {
                    if($_.Size.Y -gt 1)
                    { $_.Y++; }
                }

                $this.Blocks | Where-Object { ($_.Y + $_.Size.Y - 1) -eq $Y } | ForEach-Object {
                    $_.Y++
                }
            
                # List to store blocks that need to be removed
                [System.Collections.Generic.List[Block]]$BlocksToRemove = [System.Collections.Generic.List[Block]]::new()
            
                # Check if blocks are floating and pull them down
                $this.Blocks | ForEach-Object {
                    while ($_.IsColiding() -eq $false -and $_.Y -lt $this.Size.Y - 1) {
                        $_.Y++
                        if ($_.Y -ge $this.Size.Y - 1) {
                            break
                        }
                    }
            
                    # Check if block is out of bounds and mark for removal
                    if ($_.Y -ge $this.Size.Y) {
                        $BlocksToRemove.Add($_)
                    }
                }
            
                # Remove blocks that are out of bounds
                foreach ($block in $BlocksToRemove) {
                    $this.Blocks.Remove($block)
                }
            }
            

            Write-Host "`n" -NoNewline
            $Y++
        }

        Start-Sleep -Milliseconds (160 - ($this.Blocks.Count * 2))
    }
}
function Show-Menu([string[]]$Items) {
    [int]$menu = 1
    [int]$MenuSize = 0
    [bool]$Change = $true;

    foreach ($Item in $Items) {
        if ($Item.Length -gt $MenuSize) {
            $MenuSize = $Item.Length
        }
    }
    $MenuSize += 4
    $Logo = "
    ████████╗███████╗████████╗██████╗ ██╗███████╗
    ╚══██╔══╝██╔════╝╚══██╔══╝██╔══██╗██║██╔════╝
       ██║   █████╗     ██║   ██████╔╝██║███████╗
       ██║   ██╔══╝     ██║   ██╔══██╗██║╚════██║
       ██║   ███████╗   ██║   ██║  ██║██║███████║
       ╚═╝   ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚══════╝
                                                 
    "
    do {
        

        # Check for key presses outside the item loop
        $up = [Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::Up)
        $down = [Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::Down)
        $enter = [Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::Enter)

        # Update menu position based on key press
        if ($up -and $menu -gt 1) {
            [console]::Beep(600, 80)
            $menu--
            $Change = $true;
            Start-Sleep -Milliseconds 200
        }
        elseif ($down -and $menu -lt $Items.Count) {
            [console]::Beep(600, 80)
            $menu++
            $Change = $true;
            Start-Sleep -Milliseconds 200
        }

        if($Change)
        {
        Clear-Host
        Write-Host $Logo -ForegroundColor Cyan

        $Selector = 0

        foreach ($Item in $Items) {
            $Selector++
            [ConsoleColor]$MenuColor = [ConsoleColor]::Gray
            if ($Selector -eq $menu) {
                $MenuColor = [ConsoleColor]::DarkCyan
            }

            [int]$MenuRender = 0

            Write-Host "                     -" -NoNewline -ForegroundColor $MenuColor
            $MenuRender = 0

            $SpaceCount = (($MenuSize - $Item.Length - 1) / 2)
            do {
                Write-Host " " -NoNewline -ForegroundColor $MenuColor
                $MenuRender++
            } while ($MenuRender -lt $SpaceCount)
            Write-Host $Item -NoNewline -ForegroundColor $MenuColor
            $MenuRender = 0
            do {
                Write-Host " " -NoNewline -ForegroundColor $MenuColor
                $MenuRender++
            } while ($MenuRender -lt $SpaceCount)
            Write-Host "-" -ForegroundColor $MenuColor
            Write-Host "" -ForegroundColor $MenuColor
        }

        $Change = $false;
        Start-Sleep -Milliseconds 60
    }

    if ($enter) {
        [console]::Beep(1000, 80)
        $select = $true
    }

    } while (-not $select)

    return $menu
}

[int]$MenuResult = 1
while ($MenuResult -ne 2) {
    $MenuResult = Show-Menu -Items @("Play", "Exit")
    if ($MenuResult -eq 1) {
        # Tetris song
        $theme = {
            while ($true) {
                [Console]::Beep(658, 125)
                [Console]::Beep(1320, 500)
                [Console]::Beep(990, 250)
                [Console]::Beep(1056, 250)
                [Console]::Beep(1188, 250)
                [Console]::Beep(1320, 125)
                [Console]::Beep(1188, 125)
                [Console]::Beep(1056, 250)
                [Console]::Beep(990, 250)
                [Console]::Beep(880, 500)
                [Console]::Beep(880, 250)
                [Console]::Beep(1056, 250)
                [Console]::Beep(1320, 500)
                [Console]::Beep(1188, 250)
                [Console]::Beep(1056, 250)
                [Console]::Beep(990, 750)
                [Console]::Beep(1056, 250)
                [Console]::Beep(1188, 500)
                [Console]::Beep(1320, 500)
                [Console]::Beep(1056, 500)
                [Console]::Beep(880, 500)
                [Console]::Beep(880, 500)
                Start-Sleep -Milliseconds 250
                [Console]::Beep(1188, 500)
                [Console]::Beep(1408, 250)
                [Console]::Beep(1760, 500)
                [Console]::Beep(1584, 250)
                [Console]::Beep(1408, 250)
                [Console]::Beep(1320, 750)
                [Console]::Beep(1056, 250)
                [Console]::Beep(1320, 500)
                [Console]::Beep(1188, 250)
                [Console]::Beep(1056, 250)
                [Console]::Beep(990, 500)
                [Console]::Beep(990, 250)
                [Console]::Beep(1056, 250)
                [Console]::Beep(1188, 500)
                [Console]::Beep(1320, 500)
                [Console]::Beep(1056, 500)
                [Console]::Beep(880, 500)
                [Console]::Beep(880, 500)
                Start-Sleep -Milliseconds 500
                [Console]::Beep(660, 1000)
                [Console]::Beep(528, 1000)
                [Console]::Beep(594, 1000)
                [Console]::Beep(495, 1000)
                [Console]::Beep(528, 1000)
                [Console]::Beep(440, 1000)
                [Console]::Beep(419, 1000)
                [Console]::Beep(495, 1000)
                [Console]::Beep(660, 1000)
                [Console]::Beep(528, 1000)
                [Console]::Beep(594, 1000)
                [Console]::Beep(495, 1000)
                [Console]::Beep(528, 500)
                [Console]::Beep(660, 500)
                [Console]::Beep(880, 1000)
                [Console]::Beep(838, 2000)
                [Console]::Beep(660, 1000)
                [Console]::Beep(528, 1000)
                [Console]::Beep(594, 1000)
                [Console]::Beep(495, 1000)
                [Console]::Beep(528, 1000)
                [Console]::Beep(440, 1000)
                [Console]::Beep(419, 1000)
                [Console]::Beep(495, 1000)
                [Console]::Beep(660, 1000)
                [Console]::Beep(528, 1000)
                [Console]::Beep(594, 1000)
                [Console]::Beep(495, 1000)
                [Console]::Beep(528, 500)
                [Console]::Beep(660, 500)
                [Console]::Beep(880, 1000)
                [Console]::Beep(838, 2000)
            }
        }
        $Job = Start-ThreadJob -ScriptBlock $theme

        [Map]$Map = [Map]::new()
        [bool]$CurentBlockFalling = $false

        while (-not ($Map.Blocks | Where-Object -Property StuckAtTop -EQ $true)) {
            $Left = [Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::Left)
            $Right = [Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::Right)
            $Up = [Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::Up)
            $Down = [Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::Down)

            if ($Up) {
                $Map.CurrentBlock.Reverse()
            }
            if ($Down) {
                if ($Map.CurrentBlock.Y -lt ($Map.Size.Y / 1.5)) {
                    $Map.CurrentBlock.Y++
                }
            }
            if ($Left) {
                if (($Map.CurrentBlock.X - 1) -ge 0) {
                    $Map.CurrentBlock.X--
                }
            }

            if ($Right) {
                [bool]$CanBeMove = $true
                foreach ($Location in $Map.CurrentBlock.GetAllLocation()) {
                    if ($Location.X + 1 -gt $Map.Size.X - 1) {
                        $CanBeMove = $false
                    }
                }
                if ($CanBeMove) {
                    $Map.CurrentBlock.X++
                }
            }

            if (-not $CurentBlockFalling) {
                $Map.CurrentBlock = [Block]::new($Map)
                $Map.Blocks.Add($Map.CurrentBlock)
                $CurentBlockFalling = $true
            }
            elseif ($null -ne $Map.CurrentBlock) {
                $Map.CurrentBlock.Y++
                if ($Map.CurrentBlock.IsAt($Map.CurrentBlock.X, $Map.Size.Y-1) -or $Map.CurrentBlock.IsColiding()) {
                    $CurentBlockFalling = $false
                }
                elseif (-not $Map.Blocks.Contains($Map.CurrentBlock)) {
                    $CurentBlockFalling = $false
                }
            }
            else {
                $CurentBlockFalling = $false
            }

            $Map.Update()
        }

        Clear-Host
        $gm = "

██████╗  █████╗ ███╗   ███╗███████╗     ██████╗ ██╗   ██╗███████╗██████╗ 
██╔════╝ ██╔══██╗████╗ ████║██╔════╝    ██╔═══██╗██║   ██║██╔════╝██╔══██╗
██║  ███╗███████║██╔████╔██║█████╗      ██║   ██║██║   ██║█████╗  ██████╔╝
██║   ██║██╔══██║██║╚██╔╝██║██╔══╝      ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗
╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗    ╚██████╔╝ ╚████╔╝ ███████╗██║  ██║
 ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝     ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝
                                                                          
";
        Write-Host $gm -ForegroundColor Red;
        Stop-Job -Job $Job;
        
    }
    else {
    
        Start-Sleep -Seconds 1
        exit;
    }
    
}