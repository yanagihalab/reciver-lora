#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Raspberry Pi injectived environment setup
# ============================================================

BASE_DIR="${BASE_DIR:-$HOME/Desktop/reciver-lora}"
INJECTIVE_DIR="$BASE_DIR/injective"
BIN_DIR="$HOME/bin"

INJECTIVE_IMAGE="${INJECTIVE_IMAGE:-injectivelabs/injective-core:v1.18.3}"

KEY_NAME="${KEY_NAME:-testwallet}"
CHAIN_ID="${CHAIN_ID:-injective-888}"
NODE="${NODE:-https://injective-testnet-rpc.publicnode.com:443}"
GAS_PRICES="${GAS_PRICES:-500000000inj}"
GAS="${GAS:-500000}"
CONTRACT_ADDR="${CONTRACT_ADDR:-inj1zrg7tv5phxmu8unjhhhnzvtus30dpluaqkeln5}"

SERIAL_PORT="${SERIAL_PORT:-/dev/ttyACM0}"
BAUDRATE="${BAUDRATE:-115200}"

NODE_ID="${NODE_ID:-yamalog-7-receiver}"
PAYLOAD_NODE_ID="${PAYLOAD_NODE_ID:-node-pi-to-lora1}"
PAYLOAD_NAME="${PAYLOAD_NAME:-yama log e-paper}"
PAYLOAD_DESCRIPTION="${PAYLOAD_DESCRIPTION:-yama log QRe-paper}"
SEND_INTERVAL_SEC="${SEND_INTERVAL_SEC:-1.0}"

echo "============================================================"
echo "[1/8] Check architecture"
echo "============================================================"
ARCH="$(uname -m)"
echo "ARCH=$ARCH"

if [ "$ARCH" != "aarch64" ]; then
  echo "[WARN] This script is intended for Raspberry Pi OS 64bit / aarch64."
  echo "[WARN] Current architecture is: $ARCH"
  echo "[WARN] If this is x86_64 PC, remove '--platform linux/arm64' from ~/bin/injectived."
fi

echo
echo "============================================================"
echo "[2/8] Install required packages"
echo "============================================================"
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release jq

echo
echo "============================================================"
echo "[3/8] Check or install Docker"
echo "============================================================"
if command -v docker >/dev/null 2>&1; then
  echo "[INFO] Docker already installed:"
  docker --version
else
  echo "[INFO] Installing Docker..."
  curl -fsSL https://get.docker.com | sh
fi

echo
echo "============================================================"
echo "[4/8] Add current user to docker group"
echo "============================================================"
if groups "$USER" | grep -q '\bdocker\b'; then
  echo "[INFO] User $USER is already in docker group."
else
  echo "[INFO] Adding $USER to docker group..."
  sudo usermod -aG docker "$USER"
  echo "[WARN] You need to logout/login or reboot for docker group permission to take effect."
fi

echo
echo "============================================================"
echo "[5/8] Pull Injective Docker image"
echo "============================================================"
docker pull "$INJECTIVE_IMAGE"

echo
echo "============================================================"
echo "[6/8] Create injectived wrapper"
echo "============================================================"
mkdir -p "$BIN_DIR"

cat > "$BIN_DIR/injectived" <<EOS
#!/usr/bin/env bash
set -euo pipefail

IMAGE="\${INJECTIVE_IMAGE:-$INJECTIVE_IMAGE}"

docker run --rm -i \\
  --platform linux/arm64 \\
  -v "\$HOME/.injectived:/root/.injectived" \\
  -v "\$PWD:/work" \\
  -w /work \\
  "\$IMAGE" injectived "\$@"
EOS

chmod +x "$BIN_DIR/injectived"

if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
fi

export PATH="$HOME/bin:$PATH"

echo "[INFO] injectived wrapper created:"
which injectived || true

echo
echo "============================================================"
echo "[7/8] Create project directories and .env"
echo "============================================================"
mkdir -p "$INJECTIVE_DIR"
cd "$BASE_DIR"

cat > "$BASE_DIR/.env" <<EOS
export SERIAL_PORT=$SERIAL_PORT
export BAUDRATE=$BAUDRATE

export NODE_ID=$NODE_ID
export PAYLOAD_NODE_ID=$PAYLOAD_NODE_ID
export PAYLOAD_NAME="$PAYLOAD_NAME"
export PAYLOAD_DESCRIPTION="$PAYLOAD_DESCRIPTION"

export KEY_NAME=$KEY_NAME
export CHAIN_ID=$CHAIN_ID
export NODE=$NODE
export GAS_PRICES=$GAS_PRICES
export GAS=$GAS

export CONTRACT_ADDR=$CONTRACT_ADDR

export INJECTIVE_IMAGE=$INJECTIVE_IMAGE
export SEND_INTERVAL_SEC=$SEND_INTERVAL_SEC
EOS

echo "[INFO] .env created: $BASE_DIR/.env"
cat "$BASE_DIR/.env"

echo
echo "============================================================"
echo "[8/8] Verify injectived"
echo "============================================================"

set +e
injectived version
VERSION_STATUS=$?
set -e

if [ "$VERSION_STATUS" -ne 0 ]; then
  echo
  echo "[ERROR] injectived version failed."
  echo "[HINT] If you just added user to docker group, run:"
  echo "       sudo reboot"
  echo
  echo "[HINT] After reboot, run:"
  echo "       cd $BASE_DIR"
  echo "       source .env"
  echo "       injectived version"
  exit 1
fi

echo
echo "============================================================"
echo "[DONE] injectived environment setup completed"
echo "============================================================"
echo
echo "Next commands:"
echo
echo "cd $BASE_DIR"
echo "source .env"
echo "injectived keys add \"\$KEY_NAME\" --keyring-backend test"
echo
echo "After creating wallet:"
echo
echo "ADDR=\$(injectived keys show \"\$KEY_NAME\" -a --keyring-backend test)"
echo "echo \"\$ADDR\""
echo "injectived query bank balances \"\$ADDR\" --node \"\$NODE\""
echo
echo "IMPORTANT: Save the mnemonic phrase displayed by keys add."
