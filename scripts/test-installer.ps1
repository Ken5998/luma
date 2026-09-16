[CmdletBinding()]
param([Parameter(Mandatory)][string]$SetupPath)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
. (Join-Path $repo 'packaging\windows\deployment.ps1')
$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{AE5327E7-474B-47B6-BF01-2D5352A418AF}_is1'
if (Test-Path $uninstallKey) { throw 'An existing graphical Luma installation is registered. Run this test in a clean user account.' }
$directory = Join-Path $repo ('target\installer-test-' + [Guid]::NewGuid().ToString('N'))
$original = Get-LumaSelection
function Run-Checked($Executable, $Arguments) {
    $process = Start-Process -FilePath $Executable -ArgumentList $Arguments -WindowStyle Hidden -PassThru
    if (!$process.WaitForExit(60000)) { throw 'Installer timed out.' }
    if ($process.ExitCode -ne 0) { throw "Installer exit code: $($process.ExitCode)" }
}
try {
    # Use a known existing previous saver; the exact original registry value is restored below.
    $previous = Join-Path $repo 'target\release\Luma.scr'
    Set-LumaSelection $previous
    $arguments = @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/DIR="' + $directory + '"'))
    Run-Checked $SetupPath $arguments
    if ((Get-LumaSelection) -ne (Join-Path $directory 'Luma.scr')) { throw 'Setup did not select the installed saver.' }
    if (!(Test-Path $uninstallKey)) { throw 'Installed Apps registration is missing.' }
    if (!(Test-Path -LiteralPath (Join-Path $directory 'luma-install-helper.exe'))) { throw 'Native setup helper is missing.' }
    foreach ($legacy in @('setup-actions.ps1','deployment.ps1','Uninstall.ps1')) {
        if (Test-Path -LiteralPath (Join-Path $directory $legacy)) { throw "Graphical setup still ships legacy action script: $legacy" }
    }
    if ((Get-FileHash (Join-Path $directory 'Luma.scr')).Hash -ne (Get-FileHash $previous).Hash) { throw 'Setup changed the screensaver payload.' }
    Run-Checked $SetupPath $arguments
    $manifest = Get-Content -LiteralPath (Join-Path $directory 'installation.json') -Raw | ConvertFrom-Json
    if ($manifest.previousScreenSaver -ne $previous) { throw 'Update replaced the original screensaver selection.' }
    Run-Checked (Join-Path $directory 'unins000.exe') @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART')
    if ((Get-LumaSelection) -ne $previous) { throw 'Uninstall did not restore the original saver.' }
    if (Test-Path -LiteralPath (Join-Path $directory 'Luma.scr')) { throw 'Installed binary was not removed.' }
    if (Test-Path $uninstallKey) { throw 'Installed Apps entry was not removed.' }
    $payload = Join-Path (Split-Path $SetupPath -Parent) 'payload\Luma-windows-x64'
    Install-Luma $payload $directory
    Run-Checked $SetupPath $arguments
    $manifest = Get-Content -LiteralPath (Join-Path $directory 'installation.json') -Raw | ConvertFrom-Json
    if ($manifest.previousScreenSaver -ne $previous) { throw 'Script installation migration lost the original selection.' }
    foreach ($legacy in @('setup-actions.ps1','deployment.ps1','Uninstall.ps1')) {
        if (Test-Path -LiteralPath (Join-Path $directory $legacy)) { throw "Migration retained legacy action script: $legacy" }
    }
    Set-LumaSelection $previous
    Run-Checked (Join-Path $directory 'unins000.exe') @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART')
    if ((Get-LumaSelection) -ne $previous) { throw 'Uninstall overwrote a newer selection.' }
    Write-Output 'PASS: migration from script install and preservation of a newer selection.'
    Write-Output 'PASS: graphical install, update, registration, uninstall, and previous selection restoration.'
} finally { Set-LumaSelection $original }
