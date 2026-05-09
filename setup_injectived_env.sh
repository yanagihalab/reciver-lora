#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Raspberry Pi injectived environment setup
# This script DOES NOT create or overwrite .env.
# Run setup_env.sh first, edit .env, then run this script.
# ============================================================

BASE_DIR="${BASE_DIR:-$HOME/Desktop/reciver-lora}"
INJECTIVE_DIR="$BASE_DIR/injective"
BIN_DIR="$HOME/bin"
ENV_FILE="$BASE_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "[ERROR] .env not found: $ENV_FILE"
  echo
  echo "Run first:"
  echo "  cd $BASE_DIR"
  echo "  ./setup_env.sh"
  echo "  nano .env"
  echo
  exit 1
fi

# Load .env
set -a
source "$ENV_FILE"
set +a

# Required variables check
: "${KEY_NAME:?KEY_NAME is not set in .env}"
: "${CHAIN_ID:?CHAIN_ID is not set in .env}"
: "${NODE:?NODE is not set in .env}"
: "${GAS_PRICES:?GAS_PRICES is not set in .env}"
: "${GAS:?GAS is not set in .env}"
: "${CONTRACT_ADDR:?CONTRACT_ADDR is not set in .env}"
: "${INJECTIVE_IMAGE:?INJECTIVE_IMAGE is not set in .env}"
: "${KEYRING_BACKEND:?KEYRING_BACKEND is not set in .env}"

echo "============================================================"
echo "[1/9] Loaded .env"
echo "============================================================"
echo "ENV_FILE=$ENV_FILE"
echo "KEY_NAME=$KEY_NAME"
echo "CHAIN_ID=$CHAIN_ID"
echo "NODE=$NODE"
echo "CONTRACT_ADDR=$CONTRACT_ADDR"
echo "PAYLOAD_NODE_ID=${PAYLOAD_NODE_ID:-}"
echo "INJECTIVE_IMAGE=$INJECTIVE_IMAGE"

echo
echo "============================================================"
echo "[2/9] Check architecture"
echo "============================================================"
ARCH="$(uname -m)"
echo "ARCH=$ARCH"

if [ "$ARCH" != "aarch64" ]; then
  echo "[WARN] This script is intended for Raspberry Pi OS 64bit / aarch64."
  echo "[WARN] Current architecture is: $ARCH"
fi

echo
echo "============================================================"
echo "[3/9] Install required packages"
echo "============================================================"
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release jq

echo
echo "============================================================"
echo "[4/9] Check or install Docker"
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
echo "[5/9] Add current user to docker group"
echo "============================================================"
if groups "$USER" | grep -q '\bdocker\b'; then
  echo "[INFO] User $USER is already in docker group."
else
  echo "[INFO] Adding $USER to docker group..."
  sudo usermod -aG docker "$USER"
  echo
  echo "[WARN] Docker group permission has not been applied to this session yet."
  echo "[WARN] Please run:"
  echo
  echo "  sudo reboot"
  echo
  echo "After reboot, run again:"
  echo
  echo "  cd $BASE_DIR"
  echo "  source .env"
  echo "  ./setup_injectived_env.sh"
  echo
  exit 0
fi

echo
echo "============================================================"
echo "[6/9] Verify Docker permission"
echo "============================================================"
if ! docker version >/dev/null 2>&1; then
  echo "[ERROR] Cannot access Docker daemon."
  echo "[HINT] Run:"
  echo "  sudo reboot"
  echo
  exit 1
fi

docker --version

echo
echo "============================================================"
echo "[7/9] Pull Injective Docker image"
echo "============================================================"
docker pull "$INJECTIVE_IMAGE"

echo
echo "============================================================"
echo "[8/9] Create injectived wrapper"
echo "============================================================"
mkdir -p "$BIN_DIR"
mkdir -p "$INJECTIVE_DIR"

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
  echo "[INFO] Added ~/bin to ~/.bashrc"
fi

export PATH="$HOME/bin:$PATH"

echo "[INFO] injectived path:"
which injectived

echo
echo "============================================================"
echo "[9/9] Verify injectived and create/check wallet"
echo "============================================================"
cd "$BASE_DIR"
source "$ENV_FILE"

injectived version

if injectived keys show "$KEY_NAME" --keyring-backend "$KEYRING_BACKEND" >/dev/null 2>&1; then
  echo "[INFO] Wallet already exists: $KEY_NAME"
else
  echo "[INFO] Wallet does not exist: $KEY_NAME"
  echo
  echo "============================================================"
  echo "IMPORTANT"
  echo "============================================================"
  echo "A mnemonic phrase will be displayed."
  echo "Save it in a safe place."
  echo "It is required to recover this wallet."
  echo "============================================================"
  echo

  injectived keys add "$KEY_NAME" --keyring-backend "$KEYRING_BACKEND"
fi

ADDR="$(injectived keys show "$KEY_NAME" -a --keyring-backend "$KEYRING_BACKEND")"

echo
echo "============================================================"
echo "[DONE] Wallet information"
echo "============================================================"
echo "KEY_NAME=$KEY_NAME"
echo "ADDRESS=$ADDR"

echo
echo "============================================================"
echo "Balance"
echo "============================================================"
injectived query bank balances "$ADDR" --node "$NODE" || true

echo
echo "============================================================"
echo "[DONE] injectived environment setup completed"
echo "============================================================"
echo
echo "Next commands:"
echo
echo "cd $BASE_DIR"
echo "source .env"
echo "ADDR=\$(injectived keys show \"\$KEY_NAME\" -a --keyring-backend \"\$KEYRING_BACKEND\")"
echo "echo \"\$ADDR\""
echo "injectived query bank balances \"\$ADDR\" --node \"\$NODE\""
echo
echo "Run receiver:"
echo "python3 Receive_CSV2_BC.py"
