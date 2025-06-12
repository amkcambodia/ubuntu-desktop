#!/bin/bash

# Clean up Map Drive Configuration
echo "Starting Clean Map Drive Configuration"

if grep -q '/etc/smbcred' <<< "$(ls -ld /etc/smbcred 2>/dev/null)"; then
    echo "🗑️ Deleting existing credential directory..."
    sudo rm -rf /etc/smbcred
else
    echo "✅ Credential directory does not exist."
fi

# ----------------------------------------------------------------------------------

if grep -q '/bin/amk' <<< "$(ls -ld /bin/amk 2>/dev/null)"; then
    echo "🗑️ Deleting existing credential script..."
    sudo rm -rf /bin/amk
else
    echo "✅ Credential script does not exist."
fi

# ----------------------------------------------------------------------------------

# if [ -f /etc/xdg/autostart/smbcred.desktop ]; then
#     echo "🗑️ Deleting autostart file..."
#     sudo rm -f /etc/xdg/autostart/smbcred.desktop
# else
#     echo "✅ Autostart file does not exist."
# fi

# ----------------------------------------------------------------------------------

if grep -q '/etc/systemd/system/backup' <<< "$(ls -ld /etc/systemd/system/backup 2>/dev/null)"; then
    echo "🗑️ Deleting existing Autostart Mount Directory..."
    sudo rm -rf /etc/systemd/system/backup
else
    echo "✅ Autostart Mount Directory does not exist."
fi

# ----------------------------------------------------------------------------------

if [ -f /etc/systemd/system/mount-dfs.service ]; then
    echo "🗑️ Deleting autostart Mount..."
    sudo rm -f /etc/systemd/system/mount-dfs.service
else
    echo "✅ Autostart Mount does not exist."
fi

# ----------------------------------------------------------------------------------

# Remove script startup network LAN
if [ -f /etc/profile.d/setup_lan.sh ]; then
    echo "🗑️ Deleting autostart LAN..."
    sudo rm -f /etc/profile.d/setup_lan.sh
else
    echo "✅ Autostart LAN does not exist."
fi

# ----------------------------------------------------------------------------------

# Remove script startup network WIFI
if [ -f /etc/profile.d/startup_wifi.sh ]; then
    echo "🗑️ Deleting autostart WIFI..."
    sudo rm -f /etc/profile.d/startup_wifi.sh
else
    echo "✅ Autostart WIFI does not exist."
fi

# ----------------------------------------------------------------------------------






