# Run the BudgetWise app locally in Chrome (debug mode).
# Hot-reload keys: r = reload, R = restart, q = quit.
# Extra args are passed through, e.g. .\scripts\start-local.ps1 -d edge
$ErrorActionPreference = 'Stop'

$appDir = Join-Path $PSScriptRoot '..\apps\budget_wise_app' | Resolve-Path
Set-Location $appDir

if (-not (Test-Path '.env')) {
    Write-Error "Missing $appDir\.env (see .env.example)"
    exit 1
}

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter run -d chrome @args
