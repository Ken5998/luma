[CmdletBinding()]
param([Parameter(Mandatory)][string]$IsccPath)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
& (Join-Path $PSScriptRoot 'package-windows.ps1')
Push-Location $repo
try {
    $metadata = cargo metadata --locked --no-deps --format-version 1 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw 'Cargo metadata failed.' }
    $version = ($metadata.packages | Where-Object name -eq 'luma-desktop').version
    $output = Join-Path $metadata.target_directory "releases\$version"
    $payload = Join-Path $output 'payload'
    New-Item -ItemType Directory -Path $payload -Force | Out-Null
    Expand-Archive -LiteralPath (Join-Path $metadata.target_directory 'distribution\Luma-windows-x64.zip') -DestinationPath $payload -Force
    & $IsccPath "/DAppVersion=$version" "/DPayloadDir=$payload\Luma-windows-x64" "/DOutputDir=$output" (Join-Path $repo 'packaging\windows\Luma.iss')
    if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed.' }
    Copy-Item -LiteralPath (Join-Path $metadata.target_directory 'distribution\Luma-windows-x64.zip') -Destination (Join-Path $output "Luma-$version-windows-x64.zip") -Force
    Get-ChildItem -LiteralPath $output -File | Where-Object Extension -in @('.exe','.zip') | Sort-Object Name | ForEach-Object {
        '{0}  {1}' -f (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant(), $_.Name
    } | Set-Content -LiteralPath (Join-Path $output 'SHA256SUMS.txt') -Encoding ASCII
    Write-Output "Release packages: $output"
} finally { Pop-Location }
