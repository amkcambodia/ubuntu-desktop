#!/bin/bash

# This script installs system dependencies from a requirements file.
set -e

# ----------------------------------------------------------------------------------

# Configure LAN configurations

sudo tee /etc/polkit-1/rules.d/50-networkmanager-ubuntu-group.rules > /dev/null <<EOF
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.system" &&
        subject.isInGroup("ubuntu-group")) {
        return polkit.Result.YES;
    }
});
EOF

sudo systemctl restart polkit

# ----------------------------------------------------------------------------------

echo "Start Configuring LAN settings..."

# Create necessary directories and set permissions
sudo mkdir -p /usr/local/bin/amk && sudo chmod 755 /usr/local/bin/amk

# ----------------------------------------------------------------------------------

## Rename the LAN configuration script to setup_credentials.sh

#sudo ./network/lan/tasks/rename_lan.sh

#python3 ./network/lan/tasks/rename_network.py

# ----------------------------------------------------------------------------------

#echo "Start Configuring LAN settings..."

# Create the setup_lan.sh script in /etc/profile.d
sudo cp ./network/lan/template/setup_lan.sh /etc/profile.d/setup_lan.sh
sudo chmod 755 /etc/profile.d/setup_lan.sh && sudo chmod +x /etc/profile.d/setup_lan.sh

# Copy the setup_lan.py script to /usr/local/bin/amk
# sudo cp ./network/lan/template/setup_lan.py /usr/local/bin/amk/setup_lan.py
# sudo chmod 755 /etc/profile.d/beta_setup_lan.sh && sudo chmod +x /etc/profile.d/beta_setup_lan.sh
# sudo chmod 755 /usr/local/bin/amk/setup_lan.py && chmod 755 /usr/local/bin/amk/setup_lan.py

#sudo cp ./network/lan/template/lan_config.sh /usr/local/bin/amk/setup_lan.sh
sudo cp ./network/lan/beta/beta_setup_lan.sh /usr/local/bin/amk/setup_lan.sh
sudo chmod 755 /usr/local/bin/amk/setup_lan.sh && sudo chmod +x /usr/local/bin/amk/setup_lan.sh

# ----------------------------------------------------------------------------------

# Configure Wi-Fi settings
echo "Start Configuring WIFI settings..."

## Create the wifi directory if it doesn't exist
#sudo cp ./network/wifi/template/wifi-setting.sh /usr/local/bin/amk/wifi-setting.sh

sudo cp ./network/wifi/beta/beta_wifi_setting.sh /usr/local/bin/amk/wifi-setting.sh
sudo chmod 755 /usr/local/bin/amk/wifi-setting.sh && sudo chmod +x /usr/local/bin/amk/wifi-setting.sh


# Auto start with profile
sudo cp ./network/wifi/template/startup_wifi.sh /etc/profile.d/startup_wifi.sh
sudo chmod 755 /etc/profile.d/startup_wifi.sh && sudo chmod +x /etc/profile.d/startup_wifi.sh

# ----------------------------------------------------------------------------------

# Set permissions for the wifi-setting.sh script
sudo systemctl daemon-reload
