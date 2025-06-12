cat << 'EOF' | sudo tee /usr/local/bin/amk/allow_mount-dfs.sh > /dev/null
#!/bin/bash

RULE_FILE="/etc/polkit-1/rules.d/50-mount-dfs.rules"

echo "Creating polkit rule to allow 'ubunto-group' to manage mount-dfs.service..."

sudo bash -c "cat > \$RULE_FILE" << 'EOR'
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.systemd1.manage-units" ||
         action.id == "org.freedesktop.systemd1.restart-unit" ||
         action.id == "org.freedesktop.systemd1.start-unit" ||
         action.id == "org.freedesktop.systemd1.stop-unit") &&
        action.lookup("unit") == "mount-dfs.service" &&
        subject.isInGroup("ubunto-group")) {
        return polkit.Result.YES;
    }
});
EOR

chmod 644 \$RULE_FILE
echo "Polkit rule created at \$RULE_FILE"
EOF

chmod +x /usr/local/bin/amk/allow_mount-dfs.sh
