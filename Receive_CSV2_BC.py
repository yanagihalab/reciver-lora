#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import csv
import hashlib
import json
import os
import re
import subprocess
import time
from datetime import datetime
from pathlib import Path

import serial


PORT = os.environ.get("SERIAL_PORT", "/dev/ttyACM0")
BAUDRATE = int(os.environ.get("BAUDRATE", "115200"))

CSV_FILE = os.environ.get("CSV_FILE", "lora_log_bc.csv")

PAYLOAD_NODE_ID = os.environ.get("PAYLOAD_NODE_ID", "node-s-215b-2")
PAYLOAD_NAME = os.environ.get("PAYLOAD_NAME", "yama log e-paper")
PAYLOAD_DESCRIPTION = os.environ.get("PAYLOAD_DESCRIPTION", "yama log QRe-paper")

KEY_NAME = os.environ.get("KEY_NAME", "testwallet")
CHAIN_ID = os.environ.get("CHAIN_ID", "injective-888")
NODE = os.environ.get("NODE", "https://injective-testnet-rpc.publicnode.com:443")
GAS_PRICES = os.environ.get("GAS_PRICES", "500000000inj")
GAS = os.environ.get("GAS", "500000")
CONTRACT_ADDR = os.environ.get(
    "CONTRACT_ADDR",
    "inj1zrg7tv5phxmu8unjhhhnzvtus30dpluaqkeln5",
)

BROADCAST_MODE = os.environ.get("BROADCAST_MODE", "sync")
KEYRING_BACKEND = os.environ.get("KEYRING_BACKEND", "test")
SEND_INTERVAL_SEC = float(os.environ.get("SEND_INTERVAL_SEC", "1.0"))


def sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def parse_lora_line(line: str) -> dict:
    """
    LoRa 受信行を解析する。

    想定入力:
      recv: FFD3{"qr_id":"a5"}
      FFCC{"qr_id":"b4bb9e676e004d33b776543db9c22b29"}

    raw_qr_id には，受信した qr_id の値をそのまま入れる。
    """
    raw = line.strip()

    prefix = ""
    body = raw

    if ":" in raw:
        left, right = raw.split(":", 1)
        prefix = left.strip()
        body = right.strip()

    m = re.search(r"(\{.*\})", body)

    status = ""
    json_part = ""
    raw_qr_id = ""

    if m:
        status = body[:m.start()].strip()
        json_part = m.group(1)

        try:
            obj = json.loads(json_part)
            raw_qr_id = str(obj.get("qr_id", "")).strip()
        except json.JSONDecodeError:
            raw_qr_id = ""
    else:
        status = body[:4].strip() if len(body) >= 4 else body.strip()

    return {
        "raw": raw,
        "prefix": prefix,
        "status": status,
        "json_part": json_part,
        "raw_qr_id": raw_qr_id,
    }


def build_payload(parsed: dict) -> dict:
    """
    BC に保存する payload を作成する。

    ルール:
      raw_qr_id = 受信した qr_id
      qr_id = SHA256(raw_qr_id)
      unique_id = SHA256(qr_id + node_id)
    """
    raw_qr_id = parsed.get("raw_qr_id", "")
    hashed_qr_id = sha256_hex(raw_qr_id)
    unique_id = sha256_hex(hashed_qr_id + PAYLOAD_NODE_ID)

    return {
        "payload": {
            "node_id": PAYLOAD_NODE_ID,
            "name": PAYLOAD_NAME,
            "description": PAYLOAD_DESCRIPTION,
            "unique_id": unique_id,
            "qr_id": hashed_qr_id,
        }
    }


def send_to_contract(payload_obj: dict) -> dict:
    """
    inj_text_store コントラクトへ store.text 形式で送信する。
    """
    if not CONTRACT_ADDR:
        return {
            "ok": False,
            "txhash": "",
            "error": "CONTRACT_ADDR is empty",
            "stdout": "",
            "stderr": "",
        }

    payload_text = json.dumps(payload_obj, ensure_ascii=False, separators=(",", ":"))

    msg = {
        "store": {
            "text": payload_text
        }
    }

    cmd = [
        "injectived",
        "tx",
        "wasm",
        "execute",
        CONTRACT_ADDR,
        json.dumps(msg, ensure_ascii=False, separators=(",", ":")),
        "--from",
        KEY_NAME,
        "--keyring-backend",
        KEYRING_BACKEND,
        "--chain-id",
        CHAIN_ID,
        "--node",
        NODE,
        "--gas-prices",
        GAS_PRICES,
        "--gas",
        GAS,
        "--broadcast-mode",
        BROADCAST_MODE,
        "-y",
        "--output",
        "json",
    ]

    try:
        proc = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
            timeout=90,
        )

        txhash = ""
        error = ""

        stdout = proc.stdout.strip()
        stderr = proc.stderr.strip()

        if stdout:
            try:
                out = json.loads(stdout)
                txhash = out.get("txhash", "")
                code = out.get("code", 0)
                raw_log = out.get("raw_log", "")

                if code not in (0, "0", None):
                    error = f"tx code={code}, raw_log={raw_log}"
            except json.JSONDecodeError:
                error = "stdout is not JSON"

        if proc.returncode != 0:
            error = stderr or error or f"returncode={proc.returncode}"

        return {
            "ok": proc.returncode == 0 and error == "",
            "txhash": txhash,
            "error": error,
            "stdout": stdout,
            "stderr": stderr,
        }

    except subprocess.TimeoutExpired:
        return {
            "ok": False,
            "txhash": "",
            "error": "timeout",
            "stdout": "",
            "stderr": "",
        }
    except Exception as e:
        return {
            "ok": False,
            "txhash": "",
            "error": str(e),
            "stdout": "",
            "stderr": "",
        }


def ensure_csv_header(path: Path) -> None:
    if not path.exists() or path.stat().st_size == 0:
        with path.open("w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow([
                "time",
                "raw",
                "prefix",
                "status",
                "json_part",
                "raw_qr_id",
                "hashed_qr_id",
                "unique_id",
                "payload_text",
                "send_elapsed_sec",
                "bc_ok",
                "txhash",
                "bc_error",
            ])


def main() -> None:
    csv_path = Path(CSV_FILE)
    ensure_csv_header(csv_path)

    print("Logging start... Ctrl+Cで停止")
    print(f"PORT={PORT}")
    print(f"BAUDRATE={BAUDRATE}")
    print(f"CSV_FILE={CSV_FILE}")
    print(f"PAYLOAD_NODE_ID={PAYLOAD_NODE_ID}")
    print(f"PAYLOAD_NAME={PAYLOAD_NAME}")
    print(f"PAYLOAD_DESCRIPTION={PAYLOAD_DESCRIPTION}")
    print(f"CHAIN_ID={CHAIN_ID}")
    print(f"NODE={NODE}")
    print(f"CONTRACT_ADDR={CONTRACT_ADDR}")

    with serial.Serial(PORT, BAUDRATE, timeout=1) as ser, csv_path.open(
        "a", newline="", encoding="utf-8"
    ) as f:
        writer = csv.writer(f)

        try:
            while True:
                line = ser.readline().decode("utf-8", errors="ignore").strip()

                if not line:
                    continue

                now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

                parsed = parse_lora_line(line)
                payload_obj = build_payload(parsed)
                payload_text = json.dumps(payload_obj, ensure_ascii=False, separators=(",", ":"))

                hashed_qr_id = payload_obj["payload"]["qr_id"]
                unique_id = payload_obj["payload"]["unique_id"]

                send_start = time.perf_counter()
                result = send_to_contract(payload_obj)
                send_end = time.perf_counter()
                send_elapsed_sec = send_end - send_start

                writer.writerow([
                    now,
                    parsed["raw"],
                    parsed["prefix"],
                    parsed["status"],
                    parsed["json_part"],
                    parsed["raw_qr_id"],
                    hashed_qr_id,
                    unique_id,
                    payload_text,
                    f"{send_elapsed_sec:.6f}",
                    result["ok"],
                    result["txhash"],
                    result["error"],
                ])
                f.flush()

                if result["ok"]:
                    print(
                        f'{now} status={parsed["status"]} '
                        f'raw_qr_id={parsed["raw_qr_id"]} '
                        f'qr_id={hashed_qr_id} '
                        f'unique_id={unique_id} '
                        f'send_elapsed_sec={send_elapsed_sec:.3f} '
                        f'txhash={result["txhash"]}'
                    )
                else:
                    print(
                        f'{now} status={parsed["status"]} '
                        f'raw_qr_id={parsed["raw_qr_id"]} '
                        f'send_elapsed_sec={send_elapsed_sec:.3f} '
                        f'BC_SEND_FAILED={result["error"]}'
                    )

                time.sleep(SEND_INTERVAL_SEC)

        except KeyboardInterrupt:
            print("\n停止しました")


if __name__ == "__main__":
    main()
