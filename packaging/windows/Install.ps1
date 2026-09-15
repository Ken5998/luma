[CmdletBinding()]
param([switch]$NoOpen)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'deployment.ps1')
Install-Luma $PSScriptRoot (Get-LumaInstallDirectory)
if (!$NoOpen) {
    Start-Process -FilePath "$env:SystemRoot\System32\rundll32.exe" -ArgumentList 'shell32.dll,Control_RunDLL desk.cpl,,1'
}
