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
