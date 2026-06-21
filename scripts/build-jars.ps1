# build-jars.ps1
# Builds the Spring Boot jar for every service via its own Gradle wrapper, in the
# platform dependency order:
#
#   configserver -> eurekaserver -> order-service -> gatewayserver
#
# Uses `assemble` (jar only, no tests). Run from anywhere: paths are resolved
# relative to this script's location. The service repos are siblings of this repo.

$ErrorActionPreference = "Stop"

$RepoRoot      = Split-Path $PSScriptRoot -Parent
$WorkspaceRoot = Split-Path $RepoRoot -Parent

# Service dirs in dependency order.
$services = @(
    "diningplate-configserver"
    "eurekaserver"
    "order-service"
    "gatewayserver"
)

foreach ($dir in $services) {
    $serviceDir = Join-Path $WorkspaceRoot $dir
    $gradlew    = Join-Path $serviceDir "gradlew.bat"

    Write-Host "`n=== Building jar: $dir ===" -ForegroundColor Cyan
    Push-Location $serviceDir
    try {
        & $gradlew clean assemble
        if ($LASTEXITCODE -ne 0) {
            throw "Gradle assemble failed for $dir (exit $LASTEXITCODE)"
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host "`nAll jars built." -ForegroundColor Green
