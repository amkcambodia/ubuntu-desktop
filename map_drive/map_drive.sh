#!/bin/bash

set -e
# -------------
echo ""
echo "🔧 Starting configure Map Drive..."
echo ""

# ------------- Pepare dependency --------------------
echo ""
echo "Checking dependencies..."
echo ""

# Export path for dependency.sh to use
export REQUIREMENTS_FILE="./.env/requirements.txt"

# Run the dependency installer
source "./.env/check_dependency.sh"


echo ""
echo "🔧 Preparing Share Paths..."
echo ""

echo "Select setup type:"
echo "  1) HQ Staff"
echo "  2) Branch Staff"
echo "  3) Custom Setup"
read -rp "Enter choice [1-3]: " SETUP_CHOICE

case "$SETUP_CHOICE" in
    1)
        echo "✅ HQ Staff setup selected."

        # Load mount and unmount logic if needed
        source ./.env/mount_script
        source ./.env/umount_script

        # Backup old scripts if they exist
        timestamp=$(date +%Y%m%d_%H%M)
        [ -f "$MOUNT_SCRIPT" ] && cp "$MOUNT_SCRIPT" "$MOUNT_SCRIPT.bak.$timestamp"
        [ -f "$UMOUNT_SCRIPT" ] && cp "$UMOUNT_SCRIPT" "$UMOUNT_SCRIPT.bak.$timestamp"

        # Copy new scripts
        echo ""
        echo "🔧 Creating Map Drive Scripts..."
        # sudo cp ./map_drive/tasks/hq_map_drive.sh "$MOUNT_SCRIPT"
        sudo cp ./map_drive/beta/beta_hq_map2.sh "$MOUNT_SCRIPT"
        sudo cp ./map_drive/scripts/umount_hq.sh "$UMOUNT_SCRIPT"

        # Make them executable
        sudo chmod 755 "$MOUNT_SCRIPT" && sudo chmod +x "$MOUNT_SCRIPT"
        # sudo chmod 755 "$UMOUNT_SCRIPT" && sudo chmod +x "$MOUNT_SCRIPT"

        # echo "✅ Mount script installed at: $MOUNT_SCRIPT"
        # echo "✅ Unmount script installed at: $UMOUNT_SCRIPT"

        # # --- Create the systemd service ---
        # echo ""
        # echo "🔧 Creating auto mount services ..."
        # SERVICE_FILE="/etc/systemd/system/mount-dfs.service"

        # if [ -f /etc/systemd/system/mount-dfs.service ]; then
        # sudo mkdir -p /etc/systemd/system/backup && sudo chmod 755 /etc/systemd/system/backup
        # mv /etc/systemd/system/mount-dfs.service /etc/systemd/system/backup/mount-dfs.service.bk-$(date +"%Y%m%d-%H%M%S")
        # fi
        
        # ./map_drive/scripts/auto_mount_service.sh
        # sudo chmod 755 "$SERVICE_FILE" && sudo chmod +x "$SERVICE_FILE"

        # --------------------------------------------------------------------------------
        ## Copy map drive template to mount path
        echo ""
        echo "🔧 Creating Map Drive Auto Mount Scripts..."

        if [ -f /etc/xdg/autostart/mount-dfs.desktop ]; then
        mv /etc/xdg/autostart/mount-dfs.desktop /etc/xdg/autostart/mount-dfs.desktop.bk-$(date +"%Y%m%d-%H%M%S")
        fi

        sudo cp ./map_drive/beta/hq_mount_dfs.desktop /etc/xdg/autostart/mount-dfs.desktop

        echo "✅ Create Map Drive Auto completed successfully."

        # --------------------------------------------------------------------------------

        # --- Reload and enable the service ---
        sudo systemctl daemon-reload
        # sudo systemctl enable mount-dfs.service

        echo ""
        echo "✅ Mount and unmount scripts created at /usr/local/bin/amk"
        # echo "✅ Systemd service created: mount-dfs.service"
        # echo "👉 Run:   sudo systemctl start mount-dfs.service"
        # echo "👉 Run:   sudo systemctl status mount-dfs.service"
        # echo "👉 Stop:  sudo systemctl stop mount-dfs.service"
        ;;
    2)
        echo "✅ Branch Staff setup selected."

        # Load mount and unmount logic if needed
        source ./.env/mount_script
        source ./.env/umount_script

        # Backup old scripts if they exist
        timestamp=$(date +%Y%m%d_%H%M)
        [ -f "$MOUNT_SCRIPT" ] && cp "$MOUNT_SCRIPT" "$MOUNT_SCRIPT.bak.$timestamp"
        [ -f "$UMOUNT_SCRIPT" ] && cp "$UMOUNT_SCRIPT" "$UMOUNT_SCRIPT.bak.$timestamp"

        # Copy new scripts
        echo ""
        echo "🔧 Creating mount and unmount scripts..."
        sudo cp ./map_drive/tasks/branch_map_drive.sh "$MOUNT_SCRIPT"
        sudo cp ./map_drive/scripts/umount_branch.sh "$UMOUNT_SCRIPT"

        # Make them executable
        sudo chmod 755 "$MOUNT_SCRIPT" && sudo chmod +x "$MOUNT_SCRIPT"
        sudo chmod 755 "$UMOUNT_SCRIPT" && sudo chmod +x "$MOUNT_SCRIPT"

        echo "✅ Mount script installed at: $MOUNT_SCRIPT"
        echo "✅ Unmount script installed at: $UMOUNT_SCRIPT"

        # --- Create the systemd service ---
        echo ""
        echo "🔧 Creating auto mount services ..."
        SERVICE_FILE="/etc/systemd/system/mount-dfs.service"

        if [ -f /etc/systemd/system/mount-dfs.service ]; then
        sudo mkdir -p /etc/systemd/system/backup && sudo chmod 755 /etc/systemd/system/backup
        mv /etc/systemd/system/mount-dfs.service /etc/systemd/system/backup/mount-dfs.service.bk-$(date +"%Y%m%d-%H%M%S")
        fi
        
        ./map_drive/scripts/auto_mount_service.sh
        sudo chmod 755 "$SERVICE_FILE" && sudo chmod +x "$SERVICE_FILE"

        # --- Reload and enable the service ---
        sudo systemctl daemon-reload
        sudo systemctl enable mount-dfs.service

        echo ""
        echo "✅ Mount and unmount scripts created at /usr/local/bin/amk"
        echo "✅ Systemd service created: mount-dfs.service"
        echo "👉 Run:   sudo systemctl start mount-dfs.service"
        echo "👉 Run:   sudo systemctl status mount-dfs.service"
        echo "👉 Stop:  sudo systemctl stop mount-dfs.service"
        ;;
    3)
        echo "🛠️  Custom Setup selected."
        echo ""
        # Known credential file path
        source ./.env/service_path
        source ./.env/credential
        source ./.env/mount_script
        source ./.env/umount_script

        # Backup old scripts if they exist
        timestamp=$(date +%Y%m%d_%H%M)
        [ -f "$MOUNT_SCRIPT" ] && cp "$MOUNT_SCRIPT" "$MOUNT_SCRIPT.bak.$timestamp"
        [ -f "$UMOUNT_SCRIPT" ] && cp "$UMOUNT_SCRIPT" "$UMOUNT_SCRIPT.bak.$timestamp"


        # Ensure script directory exists
        #sudo mkdir -p /usr/local/bin/amk
        #mkdir -p /media

        if [ ! -d /media ]; then
            echo "📁 Creating /media directory..."
            sudo mkdir -p /media
        else
            echo "📂 /media already exists."
        fi

        # Initialize mount/unmount scripts
        echo "#!/bin/bash" | sudo tee "$MOUNT_SCRIPT" > /dev/null
        echo "#!/bin/bash" | sudo tee "$UMOUNT_SCRIPT" > /dev/null
        sudo chmod +x "$MOUNT_SCRIPT" "$UMOUNT_SCRIPT"

        # Loop to accept multiple DFS mount points
        while true; do
            echo ""
            read -rp "🔹 Enter DFS Share path (e.g. //amkdfs/StaffDoc/ITD): " DFS_PATH
            read -rp "📁 Enter local mount folder (e.g. Deptpartment-N): " LOCAL_FOLDER

            MOUNT_POINT="/media/$LOCAL_FOLDER"
            sudo mkdir -p "$MOUNT_POINT"

            echo "✅ Mapping $DFS_PATH to $MOUNT_POINT"

            echo "sudo mount -t cifs '$DFS_PATH' '$MOUNT_POINT' -o credentials=$CREDENTIAL_FILE,iocharset=utf8,sec=ntlmssp" | sudo tee -a "$MOUNT_SCRIPT" > /dev/null
            echo "sudo umount '$MOUNT_POINT'" | sudo tee -a "$UMOUNT_SCRIPT" > /dev/null

            read -rp "➕ Add another DFS mount? (y/n): " REPLY
            [[ "$REPLY" =~ ^[Nn] ]] && break
        done

         # --- Create the systemd service ---
        echo ""
        echo "🔧 Creating auto mount services ..."
        SERVICE_FILE="/etc/systemd/system/mount-dfs.service"

        if [ -f /etc/systemd/system/mount-dfs.service ]; then
        sudo mkdir -p /etc/systemd/system/backup && sudo chmod 755 /etc/systemd/system/backup
        mv /etc/systemd/system/mount-dfs.service /etc/systemd/system/backup/mount-dfs.service.bk-$(date +"%Y%m%d-%H%M%S")
        fi
        
        ./map_drive/scripts/auto_mount_service.sh
        sudo chmod 755 "$SERVICE_FILE" && sudo chmod +x "$SERVICE_FILE"

        # --- Reload and enable the service ---
        sudo systemctl daemon-reload
        sudo systemctl enable mount-dfs.service

        echo ""
        echo "✅ Mount and unmount scripts created at /usr/local/bin/amk"
        echo "✅ Systemd service created: mount-dfs.service"
        echo "👉 Run:   sudo systemctl start mount-dfs.service"
        echo "👉 Run:   sudo systemctl status mount-dfs.service"
        echo "👉 Stop:  sudo systemctl stop mount-dfs.service"
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac