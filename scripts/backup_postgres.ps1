param(
    [string]$OutputPath = ".\backups\ledgerops-$((Get-Date).ToString('yyyyMMdd-HHmmss')).sql"
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$absoluteOutput = Join-Path $projectRoot $OutputPath
$outputDir = Split-Path -Parent $absoluteOutput

if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

Push-Location $projectRoot
try {
    docker compose exec -T postgres pg_dump -U postgres infinityguard | Out-File -FilePath $absoluteOutput -Encoding utf8
    Write-Host "Backup written to $absoluteOutput"
}
finally {
    Pop-Location
}
