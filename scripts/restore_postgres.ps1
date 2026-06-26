param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$absoluteInput = Resolve-Path $InputPath

Push-Location $projectRoot
try {
    Get-Content $absoluteInput -Raw | docker compose exec -T postgres psql -U postgres infinityguard
    Write-Host "Restore completed from $absoluteInput"
}
finally {
    Pop-Location
}
