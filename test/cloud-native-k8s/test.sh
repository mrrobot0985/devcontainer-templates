#!/bin/bash
set -euo pipefail

echo "Running cloud-native-k8s tests..."

# Check kubectl is installed
if ! command -v kubectl > /dev/null 2>&1; then
    echo "ERROR: kubectl is not installed"
    exit 1
fi
kubectl_version=$(kubectl version --client 2>/dev/null | head -1 || echo "present")
echo "OK — kubectl installed ($kubectl_version)"

# Check helm is installed
if ! command -v helm > /dev/null 2>&1; then
    echo "ERROR: helm is not installed"
    exit 1
fi
helm_version=$(helm version --short 2>/dev/null || echo "present")
echo "OK — helm installed ($helm_version)"

# Check Node.js is installed
if ! command -v node > /dev/null 2>&1; then
    echo "ERROR: node is not installed"
    exit 1
fi
echo "OK — node installed"

# Check Python is installed
if ! command -v python3 > /dev/null 2>&1; then
    echo "ERROR: python3 is not installed"
    exit 1
fi
echo "OK — python3 installed"

# Check Docker is available
if ! command -v docker > /dev/null 2>&1; then
    echo "ERROR: docker is not installed"
    exit 1
fi
echo "OK — docker installed"

# Owned security floor
if ! command -v non-root-enforcer > /dev/null 2>&1; then
    echo "ERROR: non-root-enforcer is not installed"
    exit 1
fi
echo "OK — non-root-enforcer installed"

if ! command -v ai-agent-sandbox-check > /dev/null 2>&1; then
    echo "ERROR: ai-agent-sandbox-check is not installed"
    exit 1
fi
echo "OK — ai-agent-sandbox installed"

if [ ! -x /usr/local/bin/container-firewall-init ]; then
    echo "ERROR: container-firewall-init is missing"
    exit 1
fi
echo "OK — container-firewall installed"

echo "All tests passed!"
