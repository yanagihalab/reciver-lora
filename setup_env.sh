#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${BASE_DIR:-$HOME/Desktop/reciver-lora}"
ENV_FILE="$BASE_DIR/.env"

mkdir -p "$BASE_DIR"

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
export NODE_ID=yamalog-13-receiver
export PAYLOAD_NODE_ID=node-pi-to-lora1
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

echo "[OK] .env created: $ENV_FILE"

# ~/.bashrc に PATH 設定を恒久追加
if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
  echo "[OK] PATH added to ~/.bashrc"
else
  echo "[INFO] PATH already exists in ~/.bashrc"
fi

echo
echo "============================================================"
echo "Environment file content"
echo "============================================================"
cat "$ENV_FILE"

echo
echo "============================================================"
echo "Next commands"
echo "============================================================"
echo "cd $BASE_DIR"
echo "source .env"
echo "which injectived"
echo "injectived version"
echo
echo "Wallet address check:"
echo 'ADDR=$(injectived keys show "$KEY_NAME" -a --keyring-backend test)'
echo 'echo "$ADDR"'
echo 'injectived query bank balances "$ADDR" --node "$NODE"'
