import serial
import csv
from datetime import datetime

PORT = "/dev/ttyACM0"   # ← ここを確認したポートに変更
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