param(
  [Parameter(Mandatory=$true)][string]$Compiler,
  [string]$CrtDirectory = 'C:\Program Files\Microsoft Visual Studio\18\Community\VC\Redist\MSVC\14.50.35710\x64\Microsoft.VC145.CRT'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$releaseSource = Join-Path $projectRoot 'build/windows/x64/runner/Release'
$bundle = Join-Path $projectRoot 'build/laptop-release/app'
$output = Join-Path $projectRoot 'build/laptop-release/output'
foreach ($required in @('liaqat_kiryana_store_pos.exe','flutter_windows.dll','sqlite3.dll','data/app.so','data/flutter_assets/NativeAssetsManifest.json')) {
  if (!(Test-Path (Join-Path $releaseSource $required))) { throw "Missing release file: $required" }
}
if (!(Test-Path $CrtDirectory)) { throw 'Visual C++ redistributable DLL directory not found' }
New-Item -ItemType Directory -Force $bundle,$output | Out-Null
Copy-Item (Join-Path $releaseSource '*') $bundle -Recurse -Force
Copy-Item (Join-Path $CrtDirectory '*.dll') $bundle -Force
# The engine consumes data/flutter_assets/NativeAssetsManifest.json. The root
# build manifest contains developer-machine absolute paths and is not shipped.
$buildManifest = Join-Path $bundle 'native_assets.json'
if (Test-Path $buildManifest) { Remove-Item -LiteralPath $buildManifest }
$storeFiles = @(Get-ChildItem $bundle -Recurse -Force -File | Where-Object { $_.Name -match '\.(db|sqlite|sqlite3)(-wal|-shm)?$' })
if ($storeFiles.Count) { throw 'A database was found in the release bundle; refusing to package it' }
Copy-Item (Join-Path $projectRoot 'docs/LAPTOP_INSTALLATION.txt') (Join-Path $bundle 'INSTALLATION.txt') -Force
& $Compiler "/DBundleDir=$bundle" "/DOutputDir=$output" (Join-Path $PSScriptRoot 'windows_installer.iss')
if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed' }
$installer = Join-Path $output 'Liaqat-Kiryana-POS-1.0.0-Windows-x64-Setup.exe'
$hash = (Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash
"$hash  $([IO.Path]::GetFileName($installer))" | Set-Content (Join-Path $output 'SHA256.txt')
Copy-Item (Join-Path $projectRoot 'docs/LAPTOP_INSTALLATION.txt') (Join-Path $output 'INSTALLATION.txt') -Force
Get-Item $installer | Select-Object FullName,Length
