# Raspberry Pi LoRa Receiver CSV Logger

## 概要

本ディレクトリは，Raspberry Pi に接続した LoRa 受信デバイスからシリアル通信で受信データを取得し，CSV ファイルに記録するための実行環境である．

Python スクリプト `Receive_CSV2.py` を実行することで，`/dev/ttyACM0` から受信したデータを読み取り，受信時刻とともに `lora_log.csv` に保存する．

本環境では，以下のような LoRa 受信データを確認済みである．

```text
2026-05-02 14:12:40 FFCC{"qr_id":"1a"}
2026-05-02 14:13:40 FFCC{"qr_id":"1b"}
2026-05-02 14:14:40 FFCB{"qr_id":"1c"}
2026-05-02 14:15:40 FFCC{"qr_id":"1d"}
2026-05-02 14:16:40 FFC9{"qr_id":"1e"}
2026-05-02 14:17:40 FFC8{"qr_id":"1f"}
2026-05-02 14:18:40 FFCC{"qr_id":"20"}
実行環境

本環境は以下を前提とする．

Raspberry Pi
Python 3
Python 仮想環境 venv
USB シリアル接続された LoRa 受信デバイス
シリアルポート /dev/ttyACM0
Python ライブラリ pyserial
ディレクトリ構成

作業ディレクトリは以下である．

~/Desktop/reciver-lora

想定するファイル構成は以下である．

reciver-lora/
├── Receive_CSV2.py
├── lora_log.csv
└── README.md

lora_log.csv は，スクリプト実行後に自動生成されるログファイルである．

シリアルポートの確認

LoRa 受信デバイスを Raspberry Pi に接続した状態で，以下のコマンドを実行する．

ls /dev/ttyACM*
ls /dev/ttyUSB*

確認結果は以下である．

/dev/ttyACM0
ls: cannot access '/dev/ttyUSB*': No such file or directory

この結果から，本環境では LoRa 受信デバイスが /dev/ttyACM0 として認識されていることが分かる．

そのため，Python スクリプトでは以下の設定を用いる．

PORT = "/dev/ttyACM0"

/dev/ttyUSB0 は存在しないため，本環境では使用しない．

Python 仮想環境

本環境では，Python 仮想環境を使用する．

仮想環境を有効化するには，作業ディレクトリで以下を実行する．

cd ~/Desktop/reciver-lora
source venv/bin/activate

仮想環境が有効化されている場合，プロンプトの先頭に以下のように表示される．

(venv)

実行例は以下である．

(venv) yamalog-7@yamalog:~/Desktop/reciver-lora $
必要な Python ライブラリ

本スクリプトでは，シリアル通信のために pyserial を使用する．

未導入の場合は，仮想環境を有効化した状態で以下を実行する．

pip install pyserial

インストール確認は以下で行う．

python3 - <<'PY'
import serial
print("pyserial OK")
PY

以下のように表示されれば，pyserial は利用可能である．

pyserial OK
ソースコード

Receive_CSV2.py は，シリアルポートからデータを読み取り，CSV に保存する Python スクリプトである．

import serial
import csv
from datetime import datetime

PORT = "/dev/ttyACM0"
BAUDRATE = 115200
CSV_FILE = "lora_log.csv"

with serial.Serial(PORT, BAUDRATE, timeout=1) as ser, open(CSV_FILE, "a", newline="") as f:
    writer = csv.writer(f)

    if f.tell() == 0:
        writer.writerow(["time", "raw", "data"])

    print("Logging start... Ctrl+Cで停止")

    try:
        while True:
            line = ser.readline().decode("utf-8", errors="ignore").strip()

            if line:
                if ":" in line:
                    data = line.split(":", 1)[1].strip()
                else:
                    data = line

                now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

                writer.writerow([now, line, data])
                f.flush()

                print(now, data)

    except KeyboardInterrupt:
        print("\n停止しました")
実行方法

作業ディレクトリに移動する．

cd ~/Desktop/reciver-lora

仮想環境を有効化する．

source venv/bin/activate

スクリプトを実行する．

python3 Receive_CSV2.py

正常に起動すると，以下のように表示される．

Logging start... Ctrl+Cで停止

LoRa データを受信すると，受信時刻と受信データが表示される．

実行例は以下である．

(venv) yamalog-7@yamalog:~/Desktop/reciver-lora $ python3 Receive_CSV2.py
Logging start... Ctrl+Cで停止
2026-05-02 14:12:40 FFCC{"qr_id":"1a"}
2026-05-02 14:13:40 FFCC{"qr_id":"1b"}
2026-05-02 14:14:40 FFCB{"qr_id":"1c"}
2026-05-02 14:15:40 FFCC{"qr_id":"1d"}
2026-05-02 14:16:40 FFC9{"qr_id":"1e"}
2026-05-02 14:17:40 FFC8{"qr_id":"1f"}
2026-05-02 14:18:40 FFCC{"qr_id":"20"}
停止方法

スクリプトを停止するには，ターミナルで以下を入力する．

Ctrl + C

停止時には以下のように表示される．

停止しました
CSV ログの確認

受信データは lora_log.csv に保存される．

ファイルの存在を確認する．

ls -l

CSV の中身を確認する．

cat lora_log.csv

末尾を継続的に確認する場合は以下を用いる．

tail -f lora_log.csv

CSV には，以下の形式で保存される．

time,raw,data
2026-05-02 14:12:40,"FFCC{""qr_id"":""1a""}","FFCC{""qr_id"":""1a""}"
2026-05-02 14:13:40,"FFCC{""qr_id"":""1b""}","FFCC{""qr_id"":""1b""}"
2026-05-02 14:14:40,"FFCB{""qr_id"":""1c""}","FFCB{""qr_id"":""1c""}"
受信データ形式

受信データは，以下のような形式である．

FFCC{"qr_id":"1a"}

このデータは，先頭に LoRa 受信状態または受信強度に相当すると考えられる値が付与され，その後ろに JSON 形式のデータが続く構造である．

例を以下に示す．

FFCC{"qr_id":"1a"}
FFCB{"qr_id":"1c"}
FFC9{"qr_id":"1e"}
FFC8{"qr_id":"1f"}

このうち，JSON 部分は以下である．

{"qr_id":"1a"}

現時点のスクリプトでは，受信行全体を raw および data として保存している．

現在確認できていること

現在，以下の点を確認済みである．

Raspberry Pi が LoRa 受信デバイスを /dev/ttyACM0 として認識している．
Python 仮想環境上で Receive_CSV2.py を実行できている．
/dev/ttyACM0 から LoRa 受信データを読み取れている．
受信データがターミナル上に表示されている．
FFCC{"qr_id":"1a"} のような JSON 付きデータを受信できている．
1分間隔で qr_id が変化したデータを受信できている．
トラブルシュート
/dev/ttyACM0 が存在しない場合

以下を実行して，接続されているシリアルデバイスを確認する．

ls /dev/ttyACM*
ls /dev/ttyUSB*

また，カーネルログを確認する．

dmesg | tail -n 30

/dev/ttyUSB0 として認識されている場合は，スクリプトの PORT を以下のように変更する．

PORT = "/dev/ttyUSB0"
Permission denied が出る場合

以下のようなエラーが出る場合がある．

PermissionError: [Errno 13] Permission denied: '/dev/ttyACM0'

この場合，現在のユーザーを dialout グループに追加する．

sudo usermod -aG dialout $USER
sudo reboot

再起動後，以下で dialout が含まれていることを確認する．

groups
No module named 'serial' が出る場合

以下のようなエラーが出る場合がある．

ModuleNotFoundError: No module named 'serial'

この場合，仮想環境を有効化した状態で pyserial をインストールする．

cd ~/Desktop/reciver-lora
source venv/bin/activate
pip install pyserial
実行コマンドまとめ

通常の実行手順は以下である．

cd ~/Desktop/reciver-lora
source venv/bin/activate
python3 Receive_CSV2.py

ログ確認は以下である．

tail -f lora_log.csv

シリアルポート確認は以下である．

ls /dev/ttyACM*
ls /dev/ttyUSB*
今後の拡張候補

今後の拡張として，以下が考えられる．

先頭の FFCC などを分離して保存する機能
JSON 部分のみを抽出して保存する機能
qr_id を独立した CSV カラムとして保存する機能
受信強度またはステータス値を別カラムに保存する機能
起動時に自動でログ取得を開始する systemd サービス化
一定時間ごとのログローテーション
受信データを Web UI に表示する機能

---

# Injective / LoRa 送信用 `.env` 設定

## 概要

本システムでは，LoRa 受信データを Raspberry Pi 上で受信し，受信した `qr_id` を加工したうえで Injective testnet の CosmWasm コントラクトへ送信する．

Python スクリプト `Receive_CSV2_BC.py` は，実行時に `.env` から以下の設定を読み込む．

- LoRa 受信用シリアルポート
- CSV ログファイル名
- Injective testnet の接続先
- 使用するウォレット名
- 送信先コントラクトアドレス
- payload に含める `node_id`
- `injectived` Docker image
- 実行時の送信間隔

`.env` を手作業で作成すると設定漏れが起きやすいため，本環境では `setup_env.sh` により `.env` を自動生成する．

---

## `.env` 作成スクリプト

以下のコマンドで，`.env` を作成するためのスクリプト `setup_env.sh` を作成する．

```bash
cd ~/Desktop/reciver-lora

cat > setup_env.sh <<'EOS'
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
EOS

chmod +x setup_env.sh
.env の作成方法

作成した setup_env.sh を実行する．

cd ~/Desktop/reciver-lora
./setup_env.sh

実行後，以下のファイルが生成される．

~/Desktop/reciver-lora/.env

.env を現在のシェルに反映する．

cd ~/Desktop/reciver-lora
source .env
.env の主な設定内容

作成される .env の主要な設定は以下である．

export SERIAL_PORT=/dev/ttyACM0
export BAUDRATE=115200
export CSV_FILE=lora_log_bc.csv

export NODE_ID=yamalog-13-receiver
export PAYLOAD_NODE_ID=node-pi-to-lora1
export PAYLOAD_NAME="yama log e-paper"
export PAYLOAD_DESCRIPTION="yama log QRe-paper"

export KEY_NAME=testwallet
export CHAIN_ID=injective-888
export NODE=https://injective-testnet-rpc.publicnode.com:443
export GAS_PRICES=500000000inj
export GAS=500000

export CONTRACT_ADDR=inj1zrg7tv5phxmu8unjhhhnzvtus30dpluaqkeln5

export INJECTIVE_IMAGE=injectivelabs/injective-core:v1.18.3
export SEND_INTERVAL_SEC=1.0
export BROADCAST_MODE=sync
export KEYRING_BACKEND=test
export PATH="$HOME/bin:$PATH"
injectived の確認

.env を読み込んだ後，injectived が利用できることを確認する．

cd ~/Desktop/reciver-lora
source .env

which injectived
injectived version

正常であれば，以下のように injectived のパスとバージョンが表示される．

/home/yamalog-13/bin/injectived
Version v1.18.3
testwallet の確認

作成済みの testwallet のアドレスを確認する．

cd ~/Desktop/reciver-lora
source .env

ADDR=$(injectived keys show "$KEY_NAME" -a --keyring-backend test)
echo "$ADDR"

実行例は以下である．

inj1jw3q27czf4j8qu8mh8ptkv49zu2udm65ngg662

残高を確認する．

injectived query bank balances "$ADDR" --node "$NODE"

残高が空の場合は，Injective testnet faucet から testnet 用 INJ を入金する必要がある．

LoRa 受信データの payload 加工

Receive_CSV2_BC.py では，LoRa で受信した qr_id をそのまま送信せず，以下のように加工する．

raw_qr_id = 受信した qr_id
qr_id = SHA256(raw_qr_id)
unique_id = SHA256(qr_id + node_id)

ここで，node_id には .env の以下の値を用いる．

export PAYLOAD_NODE_ID=node-pi-to-lora1

したがって，BC に送信される payload は以下の形式になる．

{
  "payload": {
    "node_id": "node-pi-to-lora1",
    "name": "yama log e-paper",
    "description": "yama log QRe-paper",
    "unique_id": "SHA256(qr_id + node_id)",
    "qr_id": "SHA256(受信したqr_id)"
  }
}

実際には，既存の inj_text_store コントラクトに合わせて，以下の store.text 形式で送信する．

{
  "store": {
    "text": "{\"payload\":{\"node_id\":\"node-pi-to-lora1\",\"name\":\"yama log e-paper\",\"description\":\"yama log QRe-paper\",\"unique_id\":\"...\",\"qr_id\":\"...\"}}"
  }
}
LoRa 受信 + BC 送信スクリプトの実行

.env を読み込んだうえで，Receive_CSV2_BC.py を実行する．

cd ~/Desktop/reciver-lora
source .env
python3 Receive_CSV2_BC.py

正常に動作すると，以下のように表示される．

Logging start... Ctrl+Cで停止
PORT=/dev/ttyACM0
BAUDRATE=115200
CSV_FILE=lora_log_bc.csv
PAYLOAD_NODE_ID=node-pi-to-lora1
PAYLOAD_NAME=yama log e-paper
PAYLOAD_DESCRIPTION=yama log QRe-paper
CHAIN_ID=injective-888
NODE=https://injective-testnet-rpc.publicnode.com:443
CONTRACT_ADDR=inj1zrg7tv5phxmu8unjhhhnzvtus30dpluaqkeln5

LoRa データを受信し，BC 送信に成功すると以下のようなログが表示される．

2026-05-02 16:41:40 status=FFD3 raw_qr_id=af qr_id=503126878d17fcd6bde7df320ff6eb7c278a1c42f30014a03b17f3dd0c023c1d unique_id=a4b64390716a2b481a37adaf6b85be983aea7ea3f2ef3e27c0c5dbc3292c0cc7 txhash=8522A9DFB356289FA52B63A4A72AE7B9FB9181B5CE2A09A357CC8EB554D700BD
CSV ログ確認

送信結果は lora_log_bc.csv に保存される．

cd ~/Desktop/reciver-lora
tail -n 5 lora_log_bc.csv

継続確認する場合は以下である．

tail -f lora_log_bc.csv
TX 確認

表示された txhash を用いて，ブロック取り込み結果を確認する．

TXHASH=ここに表示されたtxhash

sleep 6

injectived query tx "$TXHASH" \
  --node "$NODE" \
  --output json | jq .

code が 0 であれば，コントラクト実行は成功である．

現在の処理フロー

本システムの処理フローは以下である．

LoRa受信
  ↓
raw_qr_id 抽出
  ↓
qr_id = SHA256(raw_qr_id)
  ↓
unique_id = SHA256(qr_id + node_id)
  ↓
payload 形式へ整形
  ↓
Injective testnet の inj_text_store へ store.text として送信
  ↓
txhash を CSV に保存

