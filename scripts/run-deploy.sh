#!/bin/bash

# scripts/run-deploy.sh

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <deployment_id> <config_file>"
    exit 1
fi

DEPLOYMENT_ID=$1
CONFIG_FILE=$2

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file $CONFIG_FILE not found"
    exit 1
fi

# Parse config using jq
APP_NAME=$(jq -r '.appName' "$CONFIG_FILE")
PRIMARY_DOMAIN=$(jq -r '.primaryDomain' "$CONFIG_FILE")
DOMAINS_JSON=$(jq -r 'if has("domains") and .domains != null then .domains | tostring else "[]" end' "$CONFIG_FILE")
NGINX_CONFIG=$(jq -r '.nginxConfig' "$CONFIG_FILE")
PUBLIC_DIR=$(jq -r '.publicDir' "$CONFIG_FILE")
ACTIVE_PORT_FILE=$(jq -r '.activePortFile' "$CONFIG_FILE")
PORT1=$(jq -r '.port1' "$CONFIG_FILE")
PORT2=$(jq -r '.port2' "$CONFIG_FILE")
NODE_VERSION=$(jq -r '.nodeVersion' "$CONFIG_FILE")
ENVIRONMENT=$(jq -r '.environment' "$CONFIG_FILE")
INCLUDE_WWW=$(jq -r 'if has("includeWWW") then .includeWWW | tostring else "false" end' "$CONFIG_FILE")
PACKAGE_MANAGER=$(jq -r 'if has("packageManager") then .packageManager else "pnpm" end' "$CONFIG_FILE")
MAX_MEMORY_RESTART=$(jq -r 'if has("pm2Config") and .pm2Config.maxMemoryRestart then .pm2Config.maxMemoryRestart else "400M" end' "$CONFIG_FILE")

# Validate required fields
if [ -z "$APP_NAME" ] || [ -z "$PRIMARY_DOMAIN" ] || [ -z "$NGINX_CONFIG" ] || [ -z "$PUBLIC_DIR" ] || [ -z "$ACTIVE_PORT_FILE" ] || [ -z "$PORT1" ] || [ -z "$PORT2" ] || [ -z "$NODE_VERSION" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Missing required config fields"
    exit 1
fi

echo "Running deployment with config from $CONFIG_FILE..."
echo "Package manager: $PACKAGE_MANAGER"

# Call deploy.sh with parsed parameters
./scripts/deploy.sh \
    "$DEPLOYMENT_ID" \
    "$APP_NAME" \
    "$PRIMARY_DOMAIN" \
    "$DOMAINS_JSON" \
    "$NGINX_CONFIG" \
    "$PUBLIC_DIR" \
    "$ACTIVE_PORT_FILE" \
    "$PORT1" \
    "$PORT2" \
    "$NODE_VERSION" \
    "$ENVIRONMENT" \
    "$INCLUDE_WWW" \
    "$PACKAGE_MANAGER" \
    "$MAX_MEMORY_RESTART"