Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Создаем графическое окно для проигрывания видео
$form = New-Object System.Windows.Forms.Form
$form.Text = "Видео-презентация (7 фаз по 12 секунд)"
$form.Width = 900
$form.Height = 700
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::Black

# Элемент ActiveX для проигрывания видео (Windows Media Player)
try {
    $player = New-Object -ComObject WMPlayer.OCX
    $playerHost = New-Object System.Windows.Forms.Panel
    $playerHost.Dock = [System.Windows.Forms.DockStyle]::Fill
    $form.Controls.Add($playerHost)
    
    # Внедрение плеера в форму (требуется обработка дескриптора)
    $form.Add_Shown({
        # Убираем стандартные элементы управления плеера для чистого видеоряда
        $player.uiMode = "none"
    })
} catch {
    Write-Host "Ошибка инициализации плеера: $_"
}

# Список путей к вашим 7 видеофайлам (замените на свои пути к .mp4)
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
$timer.Interval = 500 # Проверка таймера каждые полсекунды

$timer.Add_Tick({
    $elapsed = ([DateTime]::Now - $startTime).TotalSeconds

    # Автоматическое закрытие через 84 секунды (7 фаз * 12 секунд)
    if ($elapsed -ge 84) {
        $timer.Stop()
        if ($player) { $player.close() }
        $form.Close()
        return
    }

    # Вычисляем текущую фазу (от 1 до 7)
    $currentPhase = [Math]::Floor($elapsed / 12) + 1

    # Если фаза сменилась, переключаем видео
    if ($currentPhase -ne $lastPhase) {
        $script:lastPhase = $currentPhase
        $index = $currentPhase - 1
        
        if ($index -lt $videoPaths.Length -and (Test-Path $videoPaths[$index])) {
            if ($player) {
                $player.URL = $videoPaths[$index]
                $player.controls.play()
            }
        } else {
            Write-Host "Видеофайл для фазы $currentPhase не найден по указанному пути."
        }
    }
})

$timer.Start()
[void]$form.ShowDialog()