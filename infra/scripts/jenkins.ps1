param(
    [ValidateSet("up", "down", "logs", "rebuild", "reset")]
    [string]$Action = "up"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$infraDir = (Resolve-Path (Join-Path $scriptDir "..")).Path
$jenkinsDir = Join-Path $infraDir "jenkins"
$envFile = Join-Path $infraDir ".env"
$envTemplate = Join-Path $infraDir ".env.example"
$dataDir = Join-Path $infraDir "jenkins_data"
$defaultKubeconfigFile = Join-Path $infraDir "kubeconfig"

if (-not (Test-Path $envFile)) {
    Copy-Item $envTemplate $envFile
    Write-Host "Created infra/.env from template. Update values before running pipelines."
}

if (-not (Test-Path $dataDir)) {
    New-Item -Path $dataDir -ItemType Directory | Out-Null
}

if (-not (Test-Path $defaultKubeconfigFile)) {
    New-Item -Path $defaultKubeconfigFile -ItemType File | Out-Null
}

try {
    docker info | Out-Null
}
catch {
    Write-Host "Docker Engine is not reachable."
    Write-Host "Start Docker Desktop and wait until it is running, then run this script again."
    Write-Host "Quick check: docker version"
    exit 1
}

Push-Location $jenkinsDir
try {
    switch ($Action) {
        "up" { docker compose --env-file ../.env up -d --build }
        "down" { docker compose --env-file ../.env down }
        "logs" { docker compose --env-file ../.env logs -f --tail=200 }
        "rebuild" { docker compose --env-file ../.env build --no-cache }
        "reset" { docker compose --env-file ../.env down -v --remove-orphans }
    }
}
finally {
    Pop-Location
}
