[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'deployment.ps1')
Uninstall-Luma (Get-LumaInstallDirectory)
