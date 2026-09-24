param([Parameter(Mandatory=$true)][string]$Godot, [string]$Python='python')
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent $PSScriptRoot
$enginePath=(Resolve-Path -LiteralPath $Godot).Path
Push-Location -LiteralPath $repoRoot
try {
    & $Python game/tools/prepare_assets.py
    if ($LASTEXITCODE -ne 0) { throw 'Asset preparation failed' }
    & $enginePath --headless --path game --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    & $enginePath --headless --path game --script res://tools/build_models.gd
    if ($LASTEXITCODE -ne 0) { throw "Model build failed" }
    & $enginePath --headless --path game --script res://tools/build_arenas.gd
    if ($LASTEXITCODE -ne 0) { throw 'Arena build failed' }
    New-Item -ItemType Directory -Force -Path out/InternalNCrush | Out-Null
    & $enginePath --headless --path game --export-release 'Windows Desktop' "$repoRoot/out/InternalNCrush/InternalNCrush.exe"
    if ($LASTEXITCODE -ne 0) { throw 'Export failed' }
    & $Python game/tools/package_release.py --build-dir out/InternalNCrush --output-dir out
    if ($LASTEXITCODE -ne 0) { throw 'Packaging failed' }
} finally { Pop-Location }
