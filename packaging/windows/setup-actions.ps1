param([ValidateSet('Prepare','Restore')][string]$Action, [string]$InstallDirectory)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'deployment.ps1')
$binary = Join-Path $InstallDirectory 'Luma.scr'
$manifestPath = Join-Path $InstallDirectory 'installation.json'
if (Test-Path -LiteralPath $binary) {
    $probe = [IO.File]::Open($binary, 'Open', 'ReadWrite', 'None')
    $probe.Dispose()
}
if (Test-Path -LiteralPath $manifestPath) {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.schema -ne 1) { throw 'Unsupported installation metadata.' }
} elseif ($Action -eq 'Prepare') {
    if (Test-Path -LiteralPath $binary) { throw 'Unmanaged Luma.scr found. Move it before installing.' }
    $manifest = [ordered]@{schema=1; previousScreenSaver=(Get-LumaSelection)}
    [IO.Directory]::CreateDirectory($InstallDirectory) | Out-Null
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json))
} else { throw 'Installation metadata is missing.' }
if ($Action -eq 'Restore' -and (Get-LumaSelection) -eq $binary) {
    $previous = $manifest.previousScreenSaver
    if ($previous -and (Test-Path -LiteralPath ([Environment]::ExpandEnvironmentVariables($previous)))) {
        Set-LumaSelection $previous
    } else { Set-LumaSelection $null }
}
