[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
Push-Location $repo
try {
    $cargoCommand = Get-Command cargo -ErrorAction SilentlyContinue
    if ($cargoCommand) { $cargo = $cargoCommand.Source }
    else { $cargo = Join-Path $env:USERPROFILE '.cargo\bin\cargo.exe' }
    if (!(Test-Path -LiteralPath $cargo)) { throw 'Rust/Cargo was not found. Install Rust with rustup.' }
    & $cargo build --locked --release -p luma-desktop
    if ($LASTEXITCODE -ne 0) { throw 'Luma build failed.' }
    $metadata = & $cargo metadata --locked --no-deps --format-version 1 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw 'Failed to read Cargo metadata.' }
    $release = Join-Path $metadata.target_directory 'release'
    Copy-Item -LiteralPath (Join-Path $release 'Luma.exe') -Destination (Join-Path $release 'Luma.scr')
    Copy-Item -LiteralPath (Join-Path $repo 'LICENSE') -Destination (Join-Path $release 'LICENSE')
    Write-Host "Ready: $(Join-Path $release 'Luma.scr')"
} finally { Pop-Location }
