#!/usr/bin/env bash
set -e

echo "Instalando dependencias para Octopus Tentacle..."

apt-get update
apt-get install -y \
  gnupg \
  curl \
  ca-certificates \
  apt-transport-https

echo "Configurando repositorio de Octopus..."

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://apt.octopus.com/public.key \
  | gpg --dearmor \
  -o /etc/apt/keyrings/octopus.gpg

chmod a+r /etc/apt/keyrings/octopus.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/octopus.gpg] https://apt.octopus.com/ stable main" \
  > /etc/apt/sources.list.d/octopus.list

apt-get update

echo "Instalando Tentacle..."
apt-get install -y tentacle

echo "Octopus Tentacle instalado correctamente."
