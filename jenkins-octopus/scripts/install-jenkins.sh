#!/usr/bin/env bash
set -e

echo "Instalando dependencias..."

apt-get update
apt-get install -y \
  git \
  curl \
  ca-certificates \
  fontconfig \
  openjdk-17-jre

echo "Configurando repositorio de Jenkins..."

mkdir -p /etc/apt/keyrings

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  | tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update

echo "Instalando Jenkins..."
apt-get install -y jenkins

echo "Agregando Jenkins al grupo docker..."
usermod -aG docker jenkins

systemctl enable jenkins
systemctl restart jenkins

echo "Jenkins instalado correctamente."
