mkdir -p ~/.config/autostart

cat <<EOF > /etc/xdg/autostart/startup-wifi.desktop
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/amk/wifi-setting.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=AMK WiFi Setup
Comment=Run WiFi keybinding at GUI login
EOF
