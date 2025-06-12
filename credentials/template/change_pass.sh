sudo tee /etc/profile.d/add_change_pass_shortcut.sh > /dev/null << 'EOF'
#!/bin/bash

SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
KEY="custom-keybindings"
BINDING="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/change-pass/"
CMD="/usr/local/bin/change_pass.sh"

existing=$(gsettings get $SCHEMA $KEY)

# Add shortcut only if it's not already configured
if [[ "$existing" != *"$BINDING"* ]]; then
  if [[ "$existing" == "@as []" ]]; then
    updated="['$BINDING']"
  else
    updated=$(echo "$existing" | sed "s/]$/, '$BINDING']/")
  fi

  gsettings set $SCHEMA $KEY "$updated"
  gsettings set $SCHEMA.custom-keybinding:"$BINDING" name "Change Password"
  gsettings set $SCHEMA.custom-keybinding:"$BINDING" command "$CMD"
  gsettings set $SCHEMA.custom-keybinding:"$BINDING" binding "<Control><Alt>p"
fi
EOF
sudo chmod +x /etc/profile.d/add_change_pass_shortcut.sh
