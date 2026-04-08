<#
.SYNOPSIS
    Build and deploy CloudTestingApp to local Kubernetes.
.DESCRIPTION
    Auto-detects your container runtime (Docker or Podman) and K8s cluster type
    (Docker Desktop K8s or Kind), then builds the image, loads it, and deploys.
.PARAMETER Action
    What to do: build, deploy, all (default), status, teardown, forward, infra
.EXAMPLE
    .\dev.ps1              # Build + Deploy + Port-forward
    .\dev.ps1 infra        # Deploy Postgres only + port-forward it (for F5 debugging)
    .\dev.ps1 build        # Build image only
    .\dev.ps1 deploy       # Apply K8s manifests only
    .\dev.ps1 forward      # Port-forward only
    .\dev.ps1 status       # Show pod/service status
    .\dev.ps1 teardown     # Remove everything from K8s
#>
param(
    [ValidateSet("build", "deploy", "all", "status", "teardown", "forward", "infra")]
    [string]$Action = "all"
)

$ErrorActionPreference = "Stop"
$ImageName = "cloudtestingapp"
$ImageTag = "latest"
$FullImage = "${ImageName}:${ImageTag}"
$Namespace = "default"

# --- Detect container runtime ---
function Get-ContainerRuntime {
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $info = docker info --format "{{.Name}}" 2>$null
        if ($LASTEXITCODE -eq 0) { return "docker" }
    }
    if (Get-Command podman -ErrorAction SilentlyContinue) {
        podman info >$null 2>&1
        if ($LASTEXITCODE -eq 0) { return "podman" }
    }
    throw "No container runtime found. Install Docker Desktop or Podman Desktop."
}

# --- Run Kind commands safely (suppresses Podman provider stderr warning) ---
# Kind with Podman writes "enabling experimental podman provider" to stderr,
# which PowerShell + $ErrorActionPreference=Stop treats as a terminating error.
# Delegate stderr suppression to cmd.exe so PowerShell never sees it.
function Invoke-Kind {
    param([Parameter(ValueFromRemainingArguments)][string[]]$KindArgs)
    $cmdLine = "kind $($KindArgs -join ' ') 2>nul"
    cmd /c $cmdLine
}

# --- Detect K8s cluster type ---
function Get-ClusterType {
    $context = kubectl config current-context 2>$null
    if ($context -match "docker-desktop") { return "docker-desktop" }
    if ($context -match "kind") { return "kind" }
    # Check if Kind clusters exist
    if (Get-Command kind -ErrorAction SilentlyContinue) {
        $clusters = Invoke-Kind get, clusters
        if ($clusters) { return "kind" }
    }
    # Fallback: if Docker Desktop, assume its built-in K8s
    if ($context) { return "generic" }
    throw "No Kubernetes cluster found. Enable K8s in Docker Desktop or create a Kind cluster."
}

function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }

# --- Build ---
function Invoke-Build {
    $runtime = Get-ContainerRuntime
    Write-Step "Building image with $runtime..."

    if ($runtime -eq "podman") {
        # Tag with docker.io/library/ prefix so K8s resolves it as "cloudtestingapp:latest"
        & $runtime build -t "docker.io/library/${FullImage}" .
    }
    else {
        & $runtime build -t $FullImage .
    }
    if ($LASTEXITCODE -ne 0) { throw "Image build failed." }
    Write-Host "Image built: $FullImage" -ForegroundColor Green
}

# --- Load image into cluster (Kind only) ---
function Invoke-LoadImage {
    $runtime = Get-ContainerRuntime
    $cluster = Get-ClusterType

    if ($cluster -eq "docker-desktop") {
        Write-Step "Docker Desktop K8s shares the Docker daemon - no image load needed."
        return
    }

    if ($cluster -eq "kind") {
        $kindCluster = (Invoke-Kind get, clusters | Select-Object -First 1)
        if (-not $kindCluster) { throw "No Kind cluster found. Run: kind create cluster" }

        if ($runtime -eq "docker") {
            Write-Step "Loading image into Kind cluster '$kindCluster' (docker)..."
            Invoke-Kind load, docker-image, $FullImage, --name, $kindCluster
        }
        else {
            Write-Step "Loading image into Kind cluster '$kindCluster' (podman archive)..."
            $archivePath = Join-Path $env:TEMP "cloudtestingapp.tar"
            podman save -o $archivePath "docker.io/library/${FullImage}"
            Invoke-Kind load, image-archive, $archivePath, --name, $kindCluster
            Remove-Item $archivePath -ErrorAction SilentlyContinue
        }
        if ($LASTEXITCODE -ne 0) { throw "Image load failed." }
        Write-Host "Image loaded into Kind." -ForegroundColor Green
        return
    }

    Write-Host "Unknown cluster type '$cluster' - skipping image load. You may need to load manually." -ForegroundColor Yellow
}

# --- Deploy ---
function Invoke-Deploy {
    Write-Step "Applying K8s manifests..."
    kubectl apply -f k8s/
    if ($LASTEXITCODE -ne 0) { throw "kubectl apply failed." }

    Write-Host "`nWaiting for pods to be ready..." -ForegroundColor Yellow
    kubectl rollout status deployment/cloudtestingapp --timeout=90s 2>$null
    kubectl rollout status deployment/postgres-db --timeout=90s 2>$null
    Write-Host "Deployment ready." -ForegroundColor Green
}

# --- Port Forward ---
function Invoke-Forward {
    Write-Step "Port-forwarding to http://localhost:8080 ..."
    Write-Host "Press Ctrl+C to stop.`n" -ForegroundColor Yellow
    kubectl port-forward service/cloudtestingapp 8080:80
}

# --- Status ---
function Invoke-Status {
    Write-Step "Cluster info"
    $runtime = Get-ContainerRuntime
    $cluster = Get-ClusterType
    Write-Host "  Runtime : $runtime"
    Write-Host "  Cluster : $cluster"
    Write-Host "  Context : $(kubectl config current-context 2>$null)"
    Write-Host ""
    kubectl get pods,svc -l "app in (cloudtestingapp, postgres-db)" -o wide
}

# --- Infrastructure only (Postgres in K8s, port-forwarded for local F5 debugging) ---
function Invoke-Infra {
    Write-Step "Deploying infrastructure (Postgres) to K8s..."
    kubectl apply -f k8s/postgres-dev.yaml
    kubectl apply -f k8s/configmap.yaml
    if ($LASTEXITCODE -ne 0) { throw "kubectl apply failed." }

    Write-Host "Waiting for Postgres to be ready..." -ForegroundColor Yellow
    kubectl rollout status deployment/postgres-db --timeout=90s 2>$null
    Write-Host "Postgres ready." -ForegroundColor Green

    Write-Step "Port-forwarding Postgres to localhost:5432 ..."
    Write-Host "Postgres available at localhost:5432" -ForegroundColor Green
    Write-Host "Now open the solution in Visual Studio and press F5 (use 'k8s-debug' profile)." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop.`n" -ForegroundColor Yellow
    kubectl port-forward service/postgres-db 5432:5432
}

# --- Teardown ---
function Invoke-Teardown {
    Write-Step "Removing K8s resources..."
    kubectl delete -f k8s/ --ignore-not-found
    Write-Host "Teardown complete." -ForegroundColor Green
}

# --- Main ---
switch ($Action) {
    "build"    { Invoke-Build }
    "deploy"   { Invoke-Build; Invoke-LoadImage; Invoke-Deploy }
    "all"      { Invoke-Build; Invoke-LoadImage; Invoke-Deploy; Invoke-Forward }
    "infra"    { Invoke-Infra }
    "forward"  { Invoke-Forward }
    "status"   { Invoke-Status }
    "teardown" { Invoke-Teardown }
}
