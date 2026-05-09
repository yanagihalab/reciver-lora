#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${BASE_DIR:-$HOME/Desktop/reciver-lora}"
ENV_FILE="$BASE_DIR/.env"

mkdir -p "$BASE_DIR"

if [ -f "$ENV_FILE" ]; then
  echo "[WARN] .env already exists: $ENV_FILE"
  echo "[WARN] Backup will be created: $ENV_FILE.bak.$(date '+%Y%m%d_%H%M%S')"
  cp "$ENV_FILE" "$ENV_FILE.bak.$(date '+%Y%m%d_%H%M%S')"
fi

cat > "$ENV_FILE" <<'ENVEOF'
# ============================================================
# LoRa Receiver Settings
# ============================================================
export SERIAL_PORT=/dev/ttyACM0
export BAUDRATE=115200
export CSV_FILE=lora_log_bc.csv

# ============================================================
# Node / Payload Settings
# ============================================================
export NODE_ID=yamalog-receiver
export PAYLOAD_NODE_ID=node-pi-to-lora2
export PAYLOAD_NAME="yama log e-paper"
export PAYLOAD_DESCRIPTION="yama log QRe-paper"

# ============================================================
# Injective Testnet Settings
# ============================================================
export KEY_NAME=testwallet
export CHAIN_ID=injective-888
export NODE=https://injective-testnet-rpc.publicnode.com:443
export GAS_PRICES=500000000inj
export GAS=500000

# ============================================================
# CosmWasm Contract
# ============================================================
export CONTRACT_ADDR=inj1zrg7tv5phxmu8unjhhhnzvtus30dpluaqkeln5

# ============================================================
# Docker injectived Settings
# ============================================================
export INJECTIVE_IMAGE=injectivelabs/injective-core:v1.18.3

# ============================================================
# Runtime Settings
# ============================================================
export SEND_INTERVAL_SEC=1.0
export BROADCAST_MODE=sync
export KEYRING_BACKEND=test

# ============================================================
# PATH
# ============================================================
export PATH="$HOME/bin:$PATH"
ENVEOF

echo "============================================================"
echo "[OK] .env created"
echo "============================================================"
echo "$ENV_FILE"
echo
echo "Edit it before running setup_injectived_env.sh:"
echo
echo "nano $ENV_FILE"
echo
echo "Example values to edit:"
echo "  PAYLOAD_NODE_ID=node-pi-to-lora1"
echo "  PAYLOAD_NODE_ID=node-pi-to-lora2"
echo "  NODE_ID=yamalog-8-receiver"
echo "  NODE_ID=yamalog-13-receiver"
