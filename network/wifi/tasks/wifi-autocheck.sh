sudo grep /etc/xdg/autostart/wifi-password-recovery.desktop && sudo cp /etc/xdg/autostart/wifi-password-recovery.desktop /etc/xdg/autostart/wifi-password-recovery.desktop.bk
cat <<EOF > /etc/xdg/autostart/wifi-password-recovery.desktop
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/wifi-password-recovery.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=WiFi Password Recovery
Comment=Please update new WiFi password
EOF
chmod +x /etc/xdg/autostart/smbcred.desktop
chmod 644 /etc/xdg/autostart/smbcred.desktop
