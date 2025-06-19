#!/bin/bash

mkdir -p ~/.config/systemd/user

cat <<EOF > ~/.config/systemd/user/umount-dfs.service
[Unit]
Description=Unmount DFS shares on logout
PartOf=graphical-session.target

[Service]
Type=oneshot
RemainAfterExit=true
ExecStop=sudo /usr/local/bin/amk/umount-dfs.sh
EOF

systemctl --user daemon-reload
systemctl --user enable umount-dfs.service
