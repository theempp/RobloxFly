$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$failed = @()
Get-ChildItem -LiteralPath src -Recurse -Filter *.luau | ForEach-Object {
    $output = & .\tools\luau\luau-compile.exe --null $_.FullName 2>&1
    if ($LASTEXITCODE -ne 0) { $failed += $_.FullName; Write-Output $output }
}
if ($failed.Count) { throw "Luau compilation failed: $failed" }
Write-Output 'All source modules compile.'
& .\tools\luau\luau-analyze.exe src\shared\Config.luau src\shared\Domain.luau src\shared\FlightModel.luau src\shared\Protocol.luau
if ($LASTEXITCODE -ne 0) { throw 'Pure module type analysis failed' }
& .\tools\luau\luau.exe tests\domain.luau
if ($LASTEXITCODE -ne 0) { throw 'Domain tests failed' }
& .\tools\rojo\rojo.exe build default.project.json -o build\PrivateJetCharterTycoon.rbxlx
if ($LASTEXITCODE -ne 0) { throw 'Rojo build failed' }
& .\tools\lune\lune.exe run tests\services.luau
if ($LASTEXITCODE -ne 0) { throw 'Server integration checks failed' }
& .\tools\lune\lune.exe run tools\bake.luau
if ($LASTEXITCODE -ne 0) { throw 'Geometry bake failed' }
Write-Output 'Studio-openable place built. Engine playtests are a separate gate.'
