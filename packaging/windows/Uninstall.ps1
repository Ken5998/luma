[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'deployment.ps1')
$setupUninstaller = Join-Path (Get-LumaInstallDirectory) 'unins000.exe'
if (Test-Path -LiteralPath $setupUninstaller) {
    Start-Process -FilePath $setupUninstaller
    return
}
Uninstall-Luma (Get-LumaInstallDirectory)
