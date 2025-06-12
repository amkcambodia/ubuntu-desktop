#!/bin/bash

set -e

# This script installs system dependencies from a specified requirements file.


#!/bin/bash

REQUIREMENTS_FILE="./.env/requirements.txt"

if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
  echo "❌ Requirements file not found: $REQUIREMENTS_FILE"
  exit 1
fi

echo "📦 Updating package list..."
sudo apt update

echo "🔍 Installing packages listed in $REQUIREMENTS_FILE..."

while IFS= read -r pkg || [[ -n "$pkg" ]]; do
  if [[ -n "$pkg" && ! "$pkg" =~ ^# ]]; then
    if dpkg -l | grep -qw "$pkg"; then
      echo "✅ $pkg is already installed."
    else
      echo "📦 Installing $pkg..."
      sudo apt install -y "$pkg"
    fi
  fi
done < "$REQUIREMENTS_FILE"

echo "✅ All required packages processed."

#----------------------------------------------
#REQUIREMENTS_FILE="./.env/requirements.txt"
#VENV_DIR="./.env/venv"
#
## Check if Python 3 is installed
#if ! command -v python3 &>/dev/null; then
#  echo "❌ Python 3 is not installed. Installing..."
#  sudo apt update && sudo apt install -y python3
#else
#  echo "✅ Python 3 is already installed."
#fi
#
## Check if pip3 is installed
#if ! command -v pip3 &>/dev/null; then
#  echo "❌ pip3 is not installed. Installing..."
#  sudo apt install -y python3-pip
#else
#  echo "✅ pip3 is already installed."
#fi
#
## Check if python3-venv is installed
#if ! dpkg -l | grep -q python3-venv; then
#  echo "❌ python3-venv is not installed. Installing..."
#  sudo apt install -y python3-venv
#else
#  echo "✅ python3-venv is already installed."
#fi
#
## Check for requirements file
#if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
#  echo "❌ Requirements file not found: $REQUIREMENTS_FILE"
#  exit 1
#fi
#
## Create virtual environment if not exists
#if [[ ! -d "$VENV_DIR" ]]; then
#  echo "🔧 Creating virtual environment..."
#  python3 -m venv "$VENV_DIR"
#fi
#
## Activate virtual environment
#echo "🚀 Activating virtual environment..."
#source "$VENV_DIR/bin/activate"
#
## Upgrade pip inside venv
#pip install --upgrade pip
#
## Install requirements
#echo "📦 Installing Python packages from $REQUIREMENTS_FILE..."
#pip install -r "$REQUIREMENTS_FILE"
#
#echo "✅ Setup complete. Virtual environment located at: $VENV_DIR"
#
## Install packages
#echo "📦 Installing dependencies from $REQUIREMENTS_FILE..."
#pip3 install --user -r "$REQUIREMENTS_FILE"
#echo "✅ Installation complete."

##################################################################
# ------------------- Fresh Setup Starts Here -------------------
echo ""
echo "🛠️  Select Setup Option:"
echo "  1) Fresh Setup (Full configuration)"
echo "  2) Custom Map Drive Only"
read -rp "Enter your choice [1-2]: " SETUP_OPTION

case "$SETUP_OPTION" in
  1)
    echo ""
    echo "🚀 Starting Fresh Setup..."
    ;;

  2)
    echo ""
    echo "📂 Redirecting to Custom Map Drive Script..."
    chmod +x ./map_drive/map_drive.sh
    ./map_drive/map_drive.sh
    exit 0
    ;;

  *)
    echo "❌ Invalid option. Exiting."
    exit 1
    ;;
esac

# ----------------------------------------------------------------
# 1. Configure SSSD Settings
# shellcheck disable=SC2083
echo "⚙️  Configuring autostart prompt..."
if [ ! -d /usr/local/bin/amk ]; then
    echo "📁 Creating /usr/local/bin/amk directory..."
    sudo mkdir -p /usr/local/bin/amk
    sudo chmod 755 /usr/local/bin/amk
else
    echo "📂 /usr/local/bin/amk already exists."
fi


./sssd/tasks/sssd_setting.sh
./sssd/tasks/allow_restart_mount.sh
sudo systemctl daemon-reload

# ----------------------------------------------------------------

# 2. Configure smbcred.sh
echo "⚙️  Configuring smbcred.sh..."

if [ ! -d /etc/smbcred ]; then
    echo "📁 Creating credential directory..."
    sudo mkdir -p /etc/smbcred
    sudo chown root:ubuntu-group /etc/smbcred
    sudo chmod 1770 /etc/smbcred
else
    echo "📂 Credential already exists."
fi

./credentials/setup_credentials.sh

# ----------------------------------------------------------------

# 3. Configure PAM for expired password GUI notification
./pam-config/setup_pam_d.sh

# ----------------------------------------------------------------

# 4. Configure Autostart Prompt

#sudo cp ./script/startup_all.sh /usr/local/bin/amk/autostart-prompt.sh
sudo bash -c '[ -f /usr/local/bin/amk/autostart-prompt.sh ] && mv /usr/local/bin/amk/autostart-prompt.sh /usr/local/bin/amk/autostart-prompt.sh.bk; cp ./script/startup_all.sh /usr/local/bin/amk/autostart-prompt.sh'

# ----------------------------------------------------------------

echo "Configure Network Settings..."
# 5. Configure Network Autostart Script
sudo ./network/setup_network_setting.sh

# ----------------------------------------------------------------

# 6. Configure network drive.....
sudo ./map_drive/map_drive.sh

# ----------------------------------------------------------------

echo "✅ All configurations completed successfully."