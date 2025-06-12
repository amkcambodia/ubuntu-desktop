#!/bin/bash

target_partial="Wired connection 1"
new_name="AMK-LAN"

# Get all Ethernet connections
mapfile -t ethernet_conns < <(nmcli -t -f NAME,TYPE connection show | grep ":ethernet" | cut -d: -f1)

found=0
for conn in "${ethernet_conns[@]}"; do
    if [[ "$conn" == *"$target_partial"* ]]; then
        echo "Found connection: '$conn'. Renaming to '$new_name'..."
        if nmcli connection rename "$conn" "$new_name"; then
            echo "✅ Renamed successfully."
            found=1
            break
        else
            echo "❌ Failed to rename connection '$conn'."
            exit 1
        fi
    fi
done

if [[ $found -eq 0 ]]; then
    echo "❌ No Ethernet connection matching '$target_partial' found."
fi
