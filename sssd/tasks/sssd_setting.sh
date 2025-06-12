#!/bin/bash

SSSD_CONF="/etc/sssd/sssd.conf"
BACKUP_PATH="/etc/sssd/sssd.conf.bak"

# ----------------------------------------------------------------------------------

# Error stop
# set -e

# ----------------------------------------------------------------------------------

# Create a backup first
sudo cp "$SSSD_CONF" "$BACKUP_PATH"
echo "📦 Backup saved to $BACKUP_PATH"

# ----------------------------------------------------------------------------------

# # Comment out fallback_homedir = /home/%u@%d
# sudo sed -i 's/^\(fallback_homedir *= */home\/%u@%d*\)/# \1/' "$SSSD_CONF"

# # Ensure fallback_homedir = /home/%u exists
# if ! grep -q "^fallback_homedir *= */home/%u" "$SSSD_CONF"; then
#     echo "fallback_homedir = /home/%u" | sudo tee -a "$SSSD_CONF" > /dev/null
#     echo "✅ Added: fallback_homedir = /home/%u"
# else
#     echo "ℹ️ Already configured: fallback_homedir = /home/%u"
# fi

# Comment out any line starting with fallback_homedir =
sudo sed -i 's/^\(fallback_homedir *=.*\)/# \1/' "$SSSD_CONF"

# Ensure fallback_homedir = /home/%u exists
if ! grep -q "^fallback_homedir *= */home/%u" "$SSSD_CONF"; then
    echo "fallback_homedir = /home/%u" | sudo tee -a "$SSSD_CONF" > /dev/null
    echo "✅ Added: fallback_homedir = /home/%u"
else
    echo "ℹ️ Already configured: fallback_homedir = /home/%u"
fi


# ----------------------------------------------------------------------------------

# Comment out access_provider = ad
sudo sed -i 's/^\(access_provider *= *ad\)/# \1/' "$SSSD_CONF"

# Ensure access_provider = simple exists
if ! grep -q "^access_provider *= *simple" "$SSSD_CONF"; then
    echo "access_provider = simple" | sudo tee -a "$SSSD_CONF" > /dev/null
    echo "✅ Added: access_provider = simple"
else
    echo "ℹ️ Already configured: access_provider = simple"
fi

# ----------------------------------------------------------------------------------

# Comment out use_fully_qualified_names = True
sudo sed -i 's/^\(use_fully_qualified_names *= *True\)/# \1/' "$SSSD_CONF"

# Ensure access_provider = simple exists
if ! grep -q "^use_fully_qualified_names *= *False" "$SSSD_CONF"; then
    echo "use_fully_qualified_names = False" | sudo tee -a "$SSSD_CONF" > /dev/null
    echo "✅ Added: use_fully_qualified_names = False"
else
    echo "ℹ️ Already configured: use_fully_qualified_names = False"
fi

# ----------------------------------------------------------------------------------

# Ensure simple_allow_group = ubunt-group exists
if ! grep -q "^simple_allow_group *= *ubunt-group" "$SSSD_CONF"; then
    echo "simple_allow_group = ubunt-group" | sudo tee -a "$SSSD_CONF" > /dev/null
    echo "✅ Added: simple_allow_group = ubunt-group"
else
    echo "ℹ️ Already configured: simple_allow_group = ubunt-group"
fi

# ----------------------------------------------------------------------------------

# Ensure correct permissions
sudo chmod 600 "$SSSD_CONF"
sudo chown root:root "$SSSD_CONF"

# ----------------------------------------------------------------------------------

# Restart sssd
sudo systemctl daemon-reload
sudo systemctl restart sssd && echo "🔄 sssd restarted"
