# Data Engineering with Spark

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Devcontainer template for data engineering with Apache Spark 3.5, Jupyter,
Polars, and MinIO for lakehouse-style local development.

## What's Inside

- **Apache Spark 3.5** — distributed compute engine
- **Jupyter Notebook** — interactive data exploration
- **Polars** — fast DataFrame library
- **PyArrow** — columnar data format
- **Pandas / NumPy** — data manipulation
- **scikit-learn** — machine learning
- **MinIO client** — S3-compatible object storage
- **Delta Spark** — lakehouse protocol

## Usage

```json
"image": "ghcr.io/mrrobot0985/devcontainer-templates/data-engineering-spark:latest"
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
