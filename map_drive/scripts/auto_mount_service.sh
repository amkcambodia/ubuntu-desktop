SERVICE_FILE="/etc/systemd/system/mount-dfs.service"
MOUNT_SCRIPT="/usr/local/bin/amk/mount-dfs.sh"
UMOUNT_SCRIPT="/usr/local/bin/amk/umount-dfs.sh"

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Mount DFS Share
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$MOUNT_SCRIPT
ExecStop=$UMOUNT_SCRIPT
[Install]
WantedBy=multi-user.target
EOF