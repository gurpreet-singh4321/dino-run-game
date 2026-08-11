# Automated Web Build & Sync Script for Dino Run Epochs
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Building Flutter Web Release Package... " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

Set-Location "$PSScriptRoot\..\dino_run_epochs"
flutter build web --release --base-href /game/

Write-Host "=========================================" -ForegroundColor Green
Write-Host " Syncing Output to dino_run_epochs_web... " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$targetDir = "$PSScriptRoot\game"
if (Test-Path $targetDir) {
    Remove-Item -Path $targetDir -Recurse -Force
}

New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
Copy-Item -Path "$PSScriptRoot\..\dino_run_epochs\build\web\*" -Destination $targetDir -Recurse -Force

Write-Host "SUCCESS! Dino Run Epochs Web is fully updated." -ForegroundColor Yellow
Write-Host "Serving on http://localhost:8080 ..." -ForegroundColor Yellow

Set-Location $PSScriptRoot
python -m http.server 8080
