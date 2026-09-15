#!/usr/bin/env bash
set -e

echo "Instalando dependencias..."

apt-get update
apt-get install -y \
  git \
  curl \
  jq \
  ca-certificates

echo "Creando usuario github-runner..."

if ! id "github-runner" >/dev/null 2>&1; then
  useradd -m -s /bin/bash github-runner
fi

usermod -aG docker github-runner

RUNNER_DIR="/opt/actions-runner"

mkdir -p "$RUNNER_DIR"
chown github-runner:github-runner "$RUNNER_DIR"

echo "Dependencias instaladas correctamente."

# ============================================
# CONFIGURACIÓN DEL RUNNER
# ============================================

cd "$RUNNER_DIR"

echo "Consultando la última versión del GitHub Actions Runner..."

RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/^v//')

echo "Versión encontrada: $RUNNER_VERSION"

curl -L -o actions-runner.tar.gz \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"

tar xzf actions-runner.tar.gz
rm actions-runner.tar.gz

chown -R github-runner:github-runner "$RUNNER_DIR"

echo "Instalado actions-runner..."
