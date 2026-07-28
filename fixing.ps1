Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create display window
$form = New-Object System.Windows.Forms.Form
$form.Text = "Safe GDI & Audio Demo"
$form.Width = 800
$form.Height = 600
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::Black

$rand = New-Object System.Random
$startTime = [DateTime]::Now
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 30 # ~33 FPS

$currentPhase = 1

$form.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $w = $form.ClientSize.Width
    $h = $form.ClientSize.Height
    $elapsed = ([DateTime]::Now - $startTime).TotalSeconds

    # Exit after 84 seconds total (7 phases * 12s)
    if ($elapsed -ge 84) {
        $timer.Stop()
        $form.Close()
        return
    }

    # Calculate current phase (1 to 7)
    $script:currentPhase = [Math]::Floor($elapsed / 12) + 1

    # 7 Distinct Safe Visual Patterns
    switch ($script:currentPhase) {
        1 { # Phase 1: Expanding Concentric Rings
            for ($i = 10; $i -lt 300; $i += 20) {
                $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 2)
                $g.DrawEllipse($pen, ($w/2 - $i/2), ($h/2 - $i/2), $i, $i)
            }
        }
        2 { # Phase 2: Dynamic Matrix Grid
            for ($x = 0; $x -lt $w; $x += 40) {
                for ($y = 0; $y -lt $h; $y += 40) {
                    $color = [System.Drawing.Color]::FromArgb(255, 0, $rand.Next(100, 255), 0)
                    $brush = New-Object System.Drawing.SolidBrush($color)
                    $g.FillRectangle($brush, $x, $y, 30, 30)
                }
            }
        }
        3 { # Phase 3: Sinusoidal Waves
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Magenta, 3)
            for ($x = 0; $x -lt $w; $x += 5) {
                $y = ($h / 2) + [Math]::Sin(($x + $elapsed * 100) * 0.02) * 100
                $g.FillEllipse([System.Drawing.Brushes]::Magenta, $x, [int]$y, 6, 6)
            }
        }
        4 { # Phase 4: Strobe Triangles
            $p1 = New-Object System.Drawing.Point($rand.Next(0, $w), $rand.Next(0, $h))
            $p2 = New-Object System.Drawing.Point($rand.Next(0, $w), $rand.Next(0, $h))
            $p3 = New-Object System.Drawing.Point($rand.Next(0, $w), $rand.Next(0, $h))
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
            $g.FillPolygon($brush, @($p1, $p2, $p3))
        }
        5 { # Phase 5: Rotational Spiral Lines
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Orange, 2)
            for ($a = 0; $a -lt 360; $a += 15) {
                $rad = $a * [Math]::PI / 180
                $x2 = ($w / 2) + [Math]::Cos($rad + $elapsed) * 200
                $y2 = ($h / 2) + [Math]::Sin($rad + $elapsed) * 200
                $g.DrawLine($pen, ($w / 2), ($h / 2), [int]$x2, [int]$y2)
            }
        }
        6 { # Phase 6: Checkerboard Shift
            $size = 50
            for ($x = 0; $x -lt $w; $x += $size) {
                for ($y = 0; $y -lt $h; $y += $size) {
                    if (($x + $y) % ($size * 2) -eq 0) {
                        $g.FillRectangle([System.Drawing.Brushes]::Blue, $x, $y, $size, $size)
                    }
                }
            }
        }
        7 { # Phase 7: Chaotic Particle Starburst
            for ($i = 0; $i -lt 50; $i++) {
                $rx = $rand.Next(0, $w)
                $ry = $rand.Next(0, $h)
                $g.FillRectangle([System.Drawing.Brushes]::White, $rx, $ry, 8, 8)
            }
        }
    }
})

$timer.Add_Tick({
    $form.Invalidate()
})

$form.Add_Shown({ $timer.Start() })
$form.ShowDialog()