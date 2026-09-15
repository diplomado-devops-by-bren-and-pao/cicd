#!/usr/bin/env bash
set -e

# ============================================
# DATOS A COMPLETAR
# ============================================

OCTOPUS_SERVER_URL="https://TU-INSTANCIA.octopus.app"
OCTOPUS_API_KEY="API-XXXXXXXXXXXXXXXXXXXXXXXX"
OCTOPUS_SPACE="Default"
OCTOPUS_ENVIRONMENT="Development"

TARGET_NAME="vagrant-deployment-target"
TARGET_ROLE="docker-host"

# ============================================
# CONFIGURACIÓN DEL TENTACLE
# ============================================

CONFIG_PATH="/etc/octopus/default/tentacle-default.config"
APPLICATION_PATH="/home/Octopus/Applications/"
SERVER_COMMS_PORT="10943"

echo "Creando instancia de Tentacle..."

sudo /opt/octopus/tentacle/Tentacle create-instance \
  --config "$CONFIG_PATH"

echo "Generando certificado..."

sudo /opt/octopus/tentacle/Tentacle new-certificate \
  --if-blank

echo "Configurando Tentacle en modo polling..."

sudo /opt/octopus/tentacle/Tentacle configure \
  --noListen True \
  --reset-trust \
  --app "$APPLICATION_PATH"

echo "Registrando deployment target en Octopus..."

sudo /opt/octopus/tentacle/Tentacle register-with \
  --server "$OCTOPUS_SERVER_URL" \
  --apiKey "$OCTOPUS_API_KEY" \
  --space "$OCTOPUS_SPACE" \
  --name "$TARGET_NAME" \
  --env "$OCTOPUS_ENVIRONMENT" \
  --role "$TARGET_ROLE" \
  --comms-style "TentacleActive" \
  --server-comms-port "$SERVER_COMMS_PORT"

echo "Instalando servicio..."

sudo /opt/octopus/tentacle/Tentacle service \
  --install \
  --start

echo "Deployment target registrado correctamente."
