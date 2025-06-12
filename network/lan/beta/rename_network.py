#!/usr/bin/env python3

import subprocess

old_name = "Wired connection 1"
new_name = "Office LAN"

def run(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)

# Check if the old connection exists
check = run(f"nmcli connection show \"{old_name}\"")
if check.returncode == 0:
    print(f"Renaming '{old_name}' to '{new_name}'...")
    rename = run(f"nmcli connection rename \"{old_name}\" \"{new_name}\"")
    if rename.returncode == 0:
        print("Done.")
    else:
        print(f"Failed to rename: {rename.stderr}")
else:
    print(f"Connection '{old_name}' not found.")
