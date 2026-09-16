# Pinned build tool for disposable Windows CI runners.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$toolDirectory = Join-Path (Split-Path $PSScriptRoot -Parent) 'target/tools'
$destination = Join-Path $toolDirectory 'InnoSetup-6.7.3'
$compiler = Join-Path $destination 'ISCC.exe'
$null = New-Item -ItemType Directory -Path $toolDirectory -Force
$download = Join-Path $toolDirectory 'innosetup-6.7.3.exe'
Invoke-WebRequest 'https://github.com/jrsoftware/issrc/releases/download/is-6_7_3/innosetup-6.7.3.exe' -OutFile $download
$expected = '9c73c3bae7ed48d44112a0f48e66742c00090bdb5bef71d9d3c056c66e97b732'
if ((Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash -ne $expected) { throw 'Inno Setup download hash mismatch.' }
$signature = Get-AuthenticodeSignature -LiteralPath $download
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'CN=Pyrsys B\.V\.') { throw 'Inno Setup publisher verification failed.' }
$process = Start-Process -FilePath $download -ArgumentList @('/CURRENTUSER', '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/NOICONS', "/DIR=`"$destination`"") -WindowStyle Hidden -PassThru
if (-not $process.WaitForExit(60000)) { throw 'Inno Setup installation timed out.' }
if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $compiler)) { throw 'Inno Setup installation failed.' }
Write-Output $compiler
