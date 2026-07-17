# Cloud Native Kubernetes

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Devcontainer template for cloud-native development with Kubernetes. Includes
kubectl, Helm, k3d, Tilt, and Docker-in-Docker for building and deploying to
local clusters.

## What's Inside

- **kubectl** — Kubernetes CLI
- **Helm** — Kubernetes package manager
- **k3d** — lightweight Kubernetes (k3s) in Docker
- **Tilt** — local development for Kubernetes with live reload
- **Skaffold** — CI/CD pipeline builder for Kubernetes
- **Docker-in-Docker** — build container images inside the devcontainer

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version | string | jammy |

## Usage

```json
"image": "ghcr.io/mrrobot0985/devcontainer-templates/cloud-native-k8s:latest"
```

## Forwarded Ports

| Port | Service |
|------|---------|
| 8080 | Ingress Controller (HTTP) |
| 8443 | Ingress Controller (HTTPS) |
| 30000 | NodePort Range |

## Quick Start

The bootstrap script creates a default k3d cluster named `devcluster` with 1
server and 2 agents.

```bash
# Check cluster status
kubectl get nodes

# Start Tilt for live development
tilt up

# Or use Skaffold for CI/CD
skaffold dev
```

## Notes

- The k3d cluster runs inside Docker, so it persists across devcontainer rebuilds.
- Use `k3d cluster delete devcluster` to reset the cluster.
- Tilt and Skaffold watch local files and auto-redeploy on changes.
