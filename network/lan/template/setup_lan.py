#!/usr/bin/env python3

import subprocess
import os
import sys

CON_NAME = "AMK-LAN"
CA_CERT = "/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"
CRED_FILE = os.path.expanduser("~/.smbcred")

def run_command(cmd):
    try:
        result = subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"❌ Command failed: {' '.join(cmd)}\nError: {e.stderr.strip()}")
        sys.exit(1)

# Find ethernet interface
def get_ethernet_iface():
    output = run_command(["nmcli", "-t", "device", "status"])
    for line in output.splitlines():
        parts = line.split(":")
        if len(parts) >= 3 and parts[2] == "ethernet":
            return parts[0]
    return None

def read_credentials():
    if not os.path.isfile(CRED_FILE):
        print(f"❌ Credential file not found at {CRED_FILE}")
        sys.exit(1)

    creds = {}
    with open(CRED_FILE) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, val = line.split("=", 1)
                creds[key.strip()] = val.strip()
    return creds

def main():
    iface = get_ethernet_iface()
    if not iface:
        print("❌ No Ethernet interface found.")
        sys.exit(1)

    creds = read_credentials()

    username = creds.get("username")
    password = creds.get("password")
    domain = creds.get("domain", "")

    if not username or not password:
        print("❌ Username or password not defined in credentials file.")
        sys.exit(1)

    if domain:
        identity = f"{domain}\\{username}"
    else:
        identity = username

    print(f"🔧 Configuring LAN: {CON_NAME} on interface {iface}")

    nmcli_cmd = [
        "nmcli", "connection", "add",
        "type", "ethernet",
        "ifname", iface,
        "con-name", CON_NAME,
        "802-1x.eap", "peap",
        "802-1x.identity", identity,
        "802-1x.password", password,
        "802-1x.phase2-auth", "mschapv2",
        "802-1x.ca-cert", CA_CERT,
        "802-1x.system-ca-certs", "yes",
        "connection.autoconnect", "yes"
    ]

    run_command(nmcli_cmd)

    print(f"✅ LAN profile '{CON_NAME}' created.")

if __name__ == "__main__":
    main()
