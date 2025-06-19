#!/bin/bash

# variable to hold the file path
# shellcheck disable=SC2034
FILE_PATH="/usr/local/bin/amk/mount-dfs.sh, /usr/local/bin/amk/umount-dfs.sh"


# Create directory for sudoers.d if it doesn't exist
sudo mkdir -p /etc/sudoers.d/
sudo mkdir -p /etc/sudoers.d/amk
sudo chmod 755 -R /etc/sudoers.d/

# shellcheck disable=SC2016
echo '%ubuntu-group ALL=(ALL) NOPASSWD: $FILE_PATH' | sudo tee /etc/sudoers.d/amk > /dev/null
