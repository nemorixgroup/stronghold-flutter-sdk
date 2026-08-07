# ============================================================
# pre_commit.ps1 - stronghold_flutter_sdk quality gate
# Run before every commit: .\scripts\pre_commit.ps1
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  stronghold_flutter_sdk pre-commit check" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# ---- Section 1: Format ----
Write-Host ""
Write-Host "[1/3] dart format ." -ForegroundColor Yellow
dart format .
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED: dart format encountered an error." -ForegroundColor Red
    exit 1
}
Write-Host "Format: OK (files reformatted if needed, review before committing)" -ForegroundColor Green

# ---- Section 2: Analyze ----
Write-Host ""
Write-Host "[2/3] dart analyze --fatal-infos" -ForegroundColor Yellow
dart analyze --fatal-infos
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED: Analysis errors found." -ForegroundColor Red
    exit 1
}
Write-Host "Analyze: OK" -ForegroundColor Green

# ---- Section 3: Test ----
Write-Host ""
Write-Host "[3/3] flutter test --exclude-tags=integration" -ForegroundColor Yellow
flutter test --exclude-tags=integration
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED: Tests failed." -ForegroundColor Red
    exit 1
}
Write-Host "Tests: OK" -ForegroundColor Green

# ---- Done ----
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  All checks passed. Ready to commit." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
