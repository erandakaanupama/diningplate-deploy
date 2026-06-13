# docker-build.ps1
# Reads versions from each service's gradle.properties, writes <repo>/compose/.env
# for docker compose, then builds both Docker images.
#
# Run from anywhere: paths are resolved relative to this script's location.
# Assumes the service repos are checked out as siblings of this deploy repo:
#
#   <workspace>/
#   ├── diningplate-deploy/      (this repo)
#   ├── diningplate-configserver/
#   └── order-service/

$RepoRoot      = Split-Path $PSScriptRoot -Parent
$WorkspaceRoot = Split-Path $RepoRoot -Parent

function Get-GradleVersion($serviceDir) {
    $props = Get-Content (Join-Path $WorkspaceRoot "$serviceDir/gradle.properties")
    ($props | Where-Object { $_ -match '^version=' }) -replace '^version=', ''
}

$configVersion = Get-GradleVersion "diningplate-configserver"
$orderVersion  = Get-GradleVersion "order-service"

@"
CONFIGSERVER_VERSION=$configVersion
ORDER_SERVICE_VERSION=$orderVersion
"@ | Set-Content (Join-Path $RepoRoot "compose/.env")

Write-Host "Versions: configserver=$configVersion  order-service=$orderVersion"

Write-Host "`nBuilding diningplate-configserver:$configVersion ..."
docker build `
    --file (Join-Path $WorkspaceRoot "diningplate-configserver/Dockerfile") `
    --tag "diningplate-configserver:$configVersion" `
    (Join-Path $WorkspaceRoot "diningplate-configserver")

Write-Host "`nBuilding order-service:$orderVersion ..."
docker build `
    --file (Join-Path $WorkspaceRoot "order-service/Dockerfile") `
    --tag "order-service:$orderVersion" `
    (Join-Path $WorkspaceRoot "order-service")

Write-Host "`nDone. Images:"
docker images | Select-String "configserver|order-service"
