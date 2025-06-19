#!/bin/bash

# ----------------------------------------------------------------

# 🔐 Backup PAM files before modifying
echo "Backup PAM files..."
sudo cp /etc/pam.d/common-auth /etc/pam.d/common-auth.bak
sudo cp /etc/pam.d/common-password /etc/pam.d/common-password.bak
sudo cp /etc/pam.d/common-session /etc/pam.d/common-session.bak

# ----------------------------------------------------------------
# Configure PAM for GUI common-session
./pam-config/template/pamd-d-common-session.sh

# ----------------------------------------------------------------

# Configure PAM for GUI common-auth
./pam-config/template/pamd-d-common-auth.sh

# ----------------------------------------------------------------

# Configure PAM for GUI common-password
./pam-config/template/pamd-d-common-password.sh

# ----------------------------------------------------------------

# Fix dconf profile error login screen

sudo cp ./pam-config/template/fix_dconf_profile.sh /usr/local/bin/fix_dconf_profile.sh
sudo chmod 755 /usr/local/bin/fix_dconf_profile.sh && sudo chmod +x /usr/local/bin/fix_dconf_profile.sh

# ----------------------------------------------------------------

# Configure PAM User can run mount drive script
sudo ./pam-config/tasks/setup_dfs_sudo_access.sh

# ----------------------------------------------------------------

# Configure Ignore the loca passwd user
#sudo ./pam-config/template/fix_auth_pam.sh

# ----------------------------------------------------------------
