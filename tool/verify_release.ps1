param([string]$Flutter='flutter')
$ErrorActionPreference='Stop'
$verificationRoot=Split-Path -Parent $PSScriptRoot
Push-Location $verificationRoot
New-Item -ItemType Directory -Force build/verification | Out-Null
$verificationFailure=$null
try {
  & $Flutter build windows --release --no-pub --target tool/release_smoke.dart *> build/verification/release-harness-build.log
  if($LASTEXITCODE -ne 0){throw 'Release harness build failed'}
  $verificationProcess=Start-Process -FilePath (Join-Path $verificationRoot 'build/windows/x64/runner/Release/liaqat_kiryana_store_pos.exe') -WorkingDirectory $verificationRoot -WindowStyle Hidden -PassThru
  $verificationWatch=[Diagnostics.Stopwatch]::StartNew()
  while(!$verificationProcess.WaitForExit(1000)) {
    if($verificationWatch.Elapsed.TotalSeconds -gt 180){Stop-Process -Id $verificationProcess.Id;throw 'Release harness timeout'}
  }
  $verificationProcess.Refresh()
  if($verificationProcess.ExitCode -ne 0){throw 'Release harness failed; inspect release-smoke.json'}
  $verificationResult=Get-Content build/cleanup-phase5-review/release-smoke.json -Raw | ConvertFrom-Json
  if(!$verificationResult.passed -or !$verificationResult.releaseMode -or !$verificationResult.sourceHashUnchanged){throw 'Release evidence is incomplete'}
  Write-Output $verificationResult
} catch { $verificationFailure=$_ }
finally {
  & $Flutter build windows --release --no-pub --target lib/main.dart *> build/verification/release-build.log
  if($LASTEXITCODE -ne 0){$verificationFailure='Normal release build failed'}
  Pop-Location
}
if($verificationFailure){throw $verificationFailure}
