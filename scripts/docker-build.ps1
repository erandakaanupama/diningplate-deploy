# docker-build.ps1
# Reads versions from each service's gradle.properties, writes <repo>/compose/.env
# for docker compose, then builds all service Docker images.
#
# Run from anywhere: paths are resolved relative to this script's location.
# Assumes the service repos are checked out as siblings of this deploy repo:
#
#   <workspace>/
#   ├── diningplate-deploy/      (this repo)
#   ├── diningplate-configserver/
#   ├── eurekaserver/
#   ├── order-service/
#   └── gatewayserver/

$RepoRoot      = Split-Path $PSScriptRoot -Parent
$WorkspaceRoot = Split-Path $RepoRoot -Parent

function Get-GradleVersion($serviceDir) {
    $props = Get-Content (Join-Path $WorkspaceRoot "$serviceDir/gradle.properties")
    ($props | Where-Object { $_ -match '^version=' }) -replace '^version=', ''
}

# Service dir -> image name. Order matches the runtime dependency chain:
#   configserver -> eurekaserver -> order-service -> gatewayserver
$services = [ordered]@{
    "diningplate-configserver" = @{ Image = "diningplate-configserver"; EnvVar = "CONFIGSERVER_VERSION" }
    "eurekaserver"             = @{ Image = "eurekaserver";             EnvVar = "EUREKASERVER_VERSION" }
    "order-service"            = @{ Image = "order-service";            EnvVar = "ORDER_SERVICE_VERSION" }
    "gatewayserver"            = @{ Image = "gatewayserver";            EnvVar = "GATEWAYSERVER_VERSION" }
}

# Resolve versions and write compose/.env
$envLines = @()
foreach ($dir in $services.Keys) {
    $version = Get-GradleVersion $dir
    $services[$dir].Version = $version
    $envLines += "$($services[$dir].EnvVar)=$version"
    Write-Host "$dir = $version"
}
$envLines -join "`n" | Set-Content (Join-Path $RepoRoot "compose/.env")

# Build each image
foreach ($dir in $services.Keys) {
    $image   = $services[$dir].Image
    $version = $services[$dir].Version
    Write-Host "`nBuilding ${image}:${version} ..."
    docker build `
        --file (Join-Path $WorkspaceRoot "$dir/Dockerfile") `
        --tag "${image}:${version}" `
        (Join-Path $WorkspaceRoot $dir)
}

Write-Host "`nDone. Images:"
docker images | Select-String "configserver|eurekaserver|order-service|gatewayserver"
