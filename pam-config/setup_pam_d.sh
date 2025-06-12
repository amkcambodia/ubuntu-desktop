#!/bin/bash
# Configure PAM for GUI expired password notification
./pam-config/tasks/pam-d-gui.sh
# sudo -u "$PAM_USER" zenity --error --text="🔐 Your AD password has expired. Press Ctrl+Alt+F3 to change it."
sudo cp ./pam-config/template/fix_dconf_profile.sh /usr/local/bin/fix_dconf_profile.sh
sudo chmod 755 /usr/local/bin/fix_dconf_profile.sh && sudo chmod +x /usr/local/bin/fix_dconf_profile.sh

# ----------------------------------------------------------------

# Configure PAM User can run mount drive script
sudo ./pam-config/tasks/setup_dfs_sudo_access.sh

# ----------------------------------------------------------------

# Configure Ignore the loca passwd user
sudo ./pam-config/template/fix_auth_pam.sh

# ----------------------------------------------------------------
