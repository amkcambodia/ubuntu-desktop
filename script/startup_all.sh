#!/bin/bash

# Log output
LOG="/var/log/pam_exec.log"
exec >> "$LOG" 2>&1

echo "=== $(date) Starting PAM setup ==="

# Exit on any error
set -e

# 1. Run smbcred.sh first to make sure credentials are set
#echo "[1/4] Running smbcred.sh..."
bash /bin/amk/smbcred.sh

# 2. Configure LAN
#echo "[2/4] Running LAN configuration..."
#/usr/bin/python3 /usr/local/bin/amk/setup_lan.py
/bin/bash /usr/local/bin/amk/setup_lan.sh

# 3. Configure Wi-Fi
#echo "[3/4] Running Wi-Fi configuration..."
/bin/bash /usr/local/bin/amk/wifi-setting.sh

# 4. Rename the network
#echo "[4/4] Renaming network..."
#/usr/bin/python3 /usr/local/bin/amk/rename_network.py

echo "=== $(date) PAM setup complete ==="
