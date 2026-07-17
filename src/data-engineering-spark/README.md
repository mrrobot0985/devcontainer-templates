# Data Engineering with Spark

![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat-square)

Devcontainer template for data engineering with Apache Spark 3.5, Jupyter,
Polars, MinIO, and owned security floor (container-firewall, non-root-enforcer,
ai-agent-sandbox). No Claude suite.

## Security floor (Layer D)

Owned monorepo differentiators (re-feature path from issue #66):

- Container firewall (`container-firewall:1`) — lean whitelist `github,pypi,docker,apt` for data/Python tooling
- Non-root enforcer (`non-root-enforcer:1`) — audits `remoteUser` is non-root
- AI agent sandbox (`ai-agent-sandbox:1`, preset `moderate`, `failOnWarning: false`) — runtime posture audit (DinD may warn about docker.sock; non-blocking)

No Claude suite features on this domain stack.

## What's Inside

- **Apache Spark 3.5** — distributed compute engine
- **Jupyter Notebook** — interactive data exploration
- **Polars** — fast DataFrame library
- **PyArrow** — columnar data format
- **Pandas / NumPy** — data manipulation
- **scikit-learn** — machine learning
- **MinIO client** — S3-compatible object storage
- **Delta Spark** — lakehouse protocol
- **Container firewall** (`container-firewall`) — `github,pypi,docker,apt` services
- **Non-root enforcer** (`non-root-enforcer`)
- **Agent sandbox audit** (`ai-agent-sandbox`)

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/data-engineering-spark:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer data-engineering-spark ./my-project
```

## Forwarded Ports

| Port | Service |
|------|---------|
| 8888 | Jupyter Notebook |
| 8080 | Spark Master UI |
| 4040 | Spark Application UI |

## Getting Started

1. Open the devcontainer
2. Run `jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser` in a terminal
3. Open the forwarded URL in your browser
4. Create notebooks using PySpark or Polars

## Notes

- Spark runs in local mode by default. For multi-node clusters, use Docker
  Compose or Kubernetes.
- The `bootstrap.sh` script installs Python packages on first container creation.
