# CloudTestingApp

.NET 10 Clean Architecture demo — Web API + Blazor WASM + PostgreSQL, deployed on local Kubernetes.

## Architecture

| Project | Role |
|---------|------|
| `CloudTestingApp.Api` | ASP.NET Core Minimal API host |
| `CloudTestingApp.Blazor` | Blazor WebAssembly front-end |
| `CloudTestingApp.Application` | Use cases, DTOs, services |
| `CloudTestingApp.Domain` | Entities, interfaces, Result type |
| `CloudTestingApp.Infrastructure` | EF Core / PostgreSQL persistence |

## Prerequisites

| Tool | Docker Desktop path | Podman path |
|------|---------------------|-------------|
| Container runtime | Docker Desktop | Podman Desktop |
| Kubernetes | Enable in Docker Desktop → Settings → Kubernetes | [Kind](https://kind.sigs.k8s.io/) |
| kubectl | Bundled with Docker Desktop | Install separately |
| .NET SDK | 10.0 (for local dev only) | 10.0 (for local dev only) |

## Quick Start

```powershell
# Build image + deploy to K8s + port-forward (auto-detects your runtime)
.\dev.ps1

# Then open http://localhost:8080
```

The script detects whether you have **Docker Desktop (K8s)** or **Podman + Kind** and does the right thing automatically.

## Developer Workflows

### Inner Loop — F5 Debugging with Breakpoints

Run Postgres in K8s, debug the app locally in Visual Studio with full breakpoint support:

```powershell
# 1. Start Postgres in K8s (leave this terminal running)
.\dev.ps1 infra
```

Then in Visual Studio:
1. Open `CloudTestingApp.slnx`
2. Select the **k8s-debug** launch profile (dropdown next to the green play button)
3. Press **F5**
4. Set breakpoints, inspect variables, hot reload — everything works normally

The app runs locally on `http://localhost:5133` and connects to Postgres via the K8s port-forward on `localhost:5432`.

### Outer Loop — Full K8s Deployment

Build the container image and deploy everything to K8s (app + Postgres):

```powershell
.\dev.ps1           # or: .\dev.ps1 all
# Opens on http://localhost:8080
```

### Individual Actions

```powershell
.\dev.ps1 build      # Build container image only
.\dev.ps1 deploy     # Build + load image + apply K8s manifests
.\dev.ps1 infra      # Deploy Postgres only + port-forward (for F5 debugging)
.\dev.ps1 forward    # Port-forward app only (assumes already deployed)
.\dev.ps1 status     # Show pods, services, and detected runtime
.\dev.ps1 teardown   # Remove all K8s resources
```

## How It Works

### Docker Desktop developers
1. `docker build` creates the image locally
2. Docker Desktop K8s shares the Docker daemon — the image is visible to K8s immediately
3. `kubectl apply -f k8s/` deploys everything
4. `kubectl port-forward` exposes the app on `localhost:8080`

### Podman + Kind developers
1. `podman build` creates the image
2. The image is exported via `podman save` and loaded into the Kind cluster via `kind load image-archive`
3. K8s manifests are applied the same way
4. Port-forward works identically

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/orders` | List all orders |
| GET | `/api/orders/{id}` | Get order by ID |
| POST | `/api/orders` | Create order |
| PUT | `/api/orders/{id}` | Update order |
| DELETE | `/api/orders/{id}` | Delete order |

## K8s Resources

All manifests live in `k8s/`:

- **deployment.yaml** — App deployment (2 replicas) + ClusterIP service (port 80 → 8080)
- **postgres-dev.yaml** — PostgreSQL 16 deployment + service (port 5432)
- **configmap.yaml** — Connection string config + DB secret

## Project Structure

```
├── dev.ps1                  # One-command dev script
├── Dockerfile               # Multi-stage Alpine build
├── k8s/                     # Kubernetes manifests
├── argocd-app.yaml          # ArgoCD GitOps config
└── src/
    ├── CloudTestingApp.Api/
    ├── CloudTestingApp.Application/
    ├── CloudTestingApp.Blazor/
    ├── CloudTestingApp.Domain/
    └── CloudTestingApp.Infrastructure/
```
