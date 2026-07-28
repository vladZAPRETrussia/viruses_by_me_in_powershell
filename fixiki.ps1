Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create display window
$form = New-Object System.Windows.Forms.Form
$form.Text = "Video Presentation (7 phases, 12 seconds each)"
$form.Width = 900
$form.Height = 700
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::Black

# Use WebBrowser control for stable, error-free video rendering
$browser = New-Object System.Windows.Forms.WebBrowser
$browser.Dock = [System.Windows.Forms.DockStyle]::Fill
$browser.ScriptToString = $false
$browser.ScrollBarsEnabled = $false
$form.Controls.Add($browser)

# Replace these paths with the actual paths to your 7 video files (.mp4)
$videoPaths = @(
    "C:\Path\To\Video1.mp4",
    "C:\Path\To\Video2.mp4",
    "C:\Path\To\Video3.mp4",
    "C:\Path\To\Video4.mp4",
    "C:\Path\To\Video5.mp4",
    "C:\Path\To\Video6.mp4",
    "C:\Path\To\Video7.mp4"
)

$startTime = [DateTime]::Now
$lastPhase = 0

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500 # Check timer every 0.5 seconds

$timer.Add_Tick({
    $elapsed = ([DateTime]::Now - $startTime).TotalSeconds

    # Automatically close after 84 seconds (7 phases * 12 seconds)
    if ($elapsed -ge 84) {
        $timer.Stop()
        $form.Close()
        return
    }

    # Calculate current phase (1 to 7)
    $currentPhase = [Math]::Floor($elapsed / 12) + 1

    # Switch video on phase change
    if ($currentPhase -ne $lastPhase) {
        $script:lastPhase = $currentPhase
        $index = $currentPhase - 1
        
        if ($index -lt $videoPaths.Length -and (Test-Path $videoPaths[$index])) {
            $path = $videoPaths[$index]
            # HTML5 video container with autoplay and looping
            $html = @"
            <html>
            <body style='margin:0; background-color:black; overflow:hidden; display:flex; align-items:center; justify-content:center; height:100vh;'>
                <video width='100%' height='100%' autoplay loop muted>
                    <source src='$path' type='video/mp4'>
                    Your browser does not support the video tag.
                </video>
            </body>
            </html>
"@
            $browser.DocumentText = $html
        } else {
            # Fallback text display if the video file path is invalid or missing
            $browser.DocumentText = "<html><body style='background:black; color:white; font-family:Arial; text-align:center; padding-top:200px;'><h2>Phase $currentPhase (12 seconds)</h2><p>Video file not found at path:<br>$($videoPaths[$index])</p></body></html>"
        }
    }
})

$timer.Start()
[void]$form.ShowDialog()