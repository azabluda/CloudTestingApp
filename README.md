# CloudTestingApp

.NET 10 Clean Architecture demo — Web API + Blazor WASM + PostgreSQL, with .NET Aspire orchestration and local Kubernetes deployment.

## Architecture

| Project | Role |
|---------|------|
| `CloudTestingApp.Api` | ASP.NET Core Minimal API host |
| `CloudTestingApp.Blazor` | Blazor WebAssembly front-end |
| `CloudTestingApp.Application` | Use cases, DTOs, services |
| `CloudTestingApp.Domain` | Entities, interfaces, Result type |
| `CloudTestingApp.Infrastructure` | EF Core / PostgreSQL persistence |
| `CloudTestingApp.AppHost` | .NET Aspire orchestrator (inner loop) |
| `CloudTestingApp.ServiceDefaults` | OpenTelemetry, health checks, resilience |

## Prerequisites

| Tool | Docker Desktop path | Podman path |
|------|---------------------|-------------|
| Container runtime | Docker Desktop | Podman Desktop |
| Kubernetes | Enable in Docker Desktop → Settings → Kubernetes | [Kind](https://kind.sigs.k8s.io/) |
| kubectl | Bundled with Docker Desktop | Install separately |
| .NET SDK | 10.0 | 10.0 |

## Developer Workflows

### Inner Loop — Aspire (F5 debugging with breakpoints)

Aspire starts Postgres in a container and runs the API locally under the debugger. No K8s needed.

**From CLI:**

```powershell
dotnet run --project src/CloudTestingApp.AppHost --launch-profile http
```

**From Visual Studio:**

1. Set **CloudTestingApp.AppHost** as the startup project
2. Press **F5**

Aspire opens:
- **App** on a dynamic port (shown in terminal output)
- **Dashboard** at http://localhost:15888 (logs, traces, metrics)

When you stop debugging, Postgres stays running (persistent lifetime) so restarts are instant.

### Outer Loop — Full K8s Deployment

Build the container image and deploy everything (app + Postgres) to your local K8s cluster.

```powershell
.\dev.ps1               # Build + deploy + port-forward
                         # App opens at http://localhost:8080
```

The script auto-detects **Docker Desktop K8s** vs **Podman + Kind** and handles image loading automatically.

### dev.ps1 Actions

```powershell
.\dev.ps1              # Build + deploy + port-forward (default)
.\dev.ps1 build        # Build container image only
.\dev.ps1 deploy       # Build + load image + apply K8s manifests
.\dev.ps1 infra        # Deploy Postgres only + port-forward (legacy F5 workflow)
.\dev.ps1 forward      # Port-forward app only (assumes already deployed)
.\dev.ps1 status       # Show pods, services, and detected runtime
.\dev.ps1 teardown     # Remove all K8s resources
```

## How It Works

### Inner loop (Aspire)
1. Aspire DCP starts a Postgres container via the Docker/Podman API
2. Your API runs as a local process with the debugger attached
3. Connection string is auto-injected — no config needed
4. OpenTelemetry traces flow to the Aspire dashboard

### Outer loop — Docker Desktop developers
1. `docker build` creates the image locally
2. Docker Desktop K8s shares the Docker daemon — image is visible immediately
3. `kubectl apply -f k8s/` deploys everything
4. `kubectl port-forward` exposes the app on `localhost:8080`

### Outer loop — Podman + Kind developers
1. `podman build` creates the image
2. Image is exported via `podman save` and loaded into Kind via `kind load image-archive`
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
├── dev.ps1                  # K8s build/deploy script
├── Dockerfile               # Multi-stage Alpine build
├── k8s/                     # Kubernetes manifests
├── argocd-app.yaml          # ArgoCD GitOps config
└── src/
    ├── CloudTestingApp.AppHost/         # Aspire orchestrator
    ├── CloudTestingApp.ServiceDefaults/ # Shared defaults
    ├── CloudTestingApp.Api/
    ├── CloudTestingApp.Application/
    ├── CloudTestingApp.Blazor/
    ├── CloudTestingApp.Domain/
    └── CloudTestingApp.Infrastructure/
```
