#!/bin/bash
set -euo pipefail

# Cloud Native Kubernetes — bootstrap script
# Installs k3d and Tilt for local Kubernetes development

K3D_VERSION="v5.7.4"
TILT_VERSION="v0.33.22"

echo "Installing k3d ${K3D_VERSION}..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG="${K3D_VERSION}" bash

echo "Installing Tilt ${TILT_VERSION}..."
arch="$(uname -m)"
curl -fsSL "https://github.com/tilt-dev/tilt/releases/download/${TILT_VERSION}/tilt.${TILT_VERSION#v}.linux-${arch}.tar.gz" | tar -xzv -C /usr/local/bin tilt

echo "Installing additional tools..."
# skaffold for CI/CD pipelines
curl -Lo /usr/local/bin/skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
chmod +x /usr/local/bin/skaffold

echo "Creating default k3d cluster (if not exists)..."
if ! k3d cluster list | grep -q "devcluster"; then
    k3d cluster create devcluster \
        --servers 1 \
        --agents 2 \
        --port "8080:80@loadbalancer" \
        --port "8443:443@loadbalancer" \
        --wait
    echo "k3d cluster 'devcluster' created"
else
    echo "k3d cluster 'devcluster' already exists"
fi

echo "Cloud Native Kubernetes environment ready."
echo "  kubectl: $(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')"
echo "  helm: $(helm version --short)"
echo "  k3d: $(k3d version | head -1)"
echo "  tilt: $(tilt version | head -1)"
echo "  skaffold: $(skaffold version)"
echo ""
echo "Quick start:"
echo "  kubectl get nodes"
echo "  tilt up"
echo "  skaffold dev"
