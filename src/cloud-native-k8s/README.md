# Cloud Native Kubernetes

![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat-square)

Devcontainer template for cloud-native development with Kubernetes. Includes
kubectl, Helm, k3d, Tilt, Docker-in-Docker, and owned security floor
(container-firewall, non-root-enforcer, ai-agent-sandbox). No Claude suite.

## Security floor (Layer D)

Owned monorepo differentiators (re-feature path from issue #66):

- Container firewall (`container-firewall:1`) — lean whitelist `github,docker,npm,apt` for registry and k8s tooling
- Non-root enforcer (`non-root-enforcer:1`) — audits `remoteUser` is non-root
- AI agent sandbox (`ai-agent-sandbox:1`, preset `moderate`, `failOnWarning: false`) — runtime posture audit (DinD may warn about docker.sock; non-blocking)

No Claude suite features on this domain stack.

## What's Inside

- **kubectl** — Kubernetes CLI
- **Helm** — Kubernetes package manager
- **k3d** — lightweight Kubernetes (k3s) in Docker
- **Tilt** — local development for Kubernetes with live reload
- **Skaffold** — CI/CD pipeline builder for Kubernetes
- **Docker-in-Docker** — build container images inside the devcontainer
- **Container firewall** (`container-firewall`) — `github,docker,npm,apt` services
- **Non-root enforcer** (`non-root-enforcer`)
- **Agent sandbox audit** (`ai-agent-sandbox`)

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/cloud-native-k8s:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer cloud-native-k8s ./my-project
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
