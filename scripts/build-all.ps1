# build-all.ps1
# One-shot pipeline: build every service jar, then build the Docker images.
#
#   1. build-jars.ps1    -> assembles each service's Boot jar (build/libs)
#   2. docker-build.ps1  -> tags images from gradle.properties, writes compose/.env
#
# Run from anywhere: paths are resolved relative to this script's location.

$ErrorActionPreference = "Stop"

Write-Host "==> Step 1/2: building service jars" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "build-jars.ps1")
if ($LASTEXITCODE -ne 0) { throw "build-jars.ps1 failed (exit $LASTEXITCODE)" }

Write-Host "`n==> Step 2/2: building Docker images" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "docker-build.ps1")
if ($LASTEXITCODE -ne 0) { throw "docker-build.ps1 failed (exit $LASTEXITCODE)" }

Write-Host "`nPipeline complete: jars + images built." -ForegroundColor Green
