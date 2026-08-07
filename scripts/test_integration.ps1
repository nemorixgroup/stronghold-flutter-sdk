# ============================================================
# test_integration.ps1 - runs tests tagged 'integration'
# These hit real networks (Testnet, Mainnet reads). Run manually,
# not as part of every commit.
# Usage: .\scripts\test_integration.ps1
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Running integration tests (real network calls)..." -ForegroundColor Yellow
flutter test --tags=integration

if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED: Integration tests failed." -ForegroundColor Red
    exit 1
}

Write-Host "Integration tests: OK" -ForegroundColor Green
