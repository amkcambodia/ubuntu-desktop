# Welcome to Ubuntu Setup Scripts!
# Instruction

## Join Domain 
After install OS to computer will require internet access to install some software/package requirement.
- Install Dependency for join Ubuntu to join domain
  ```
  sudo apt install realmd sssd sssd-tools adcli adsys certmonger python3-cepces -y
  ```
- Test discover connection to domain
  ```
  realm discover -v amkdc02.amkcambodia.com
  ```
  Expected result:
  ```
  * Resolving: _ldap._tcp.amkdc02.amkcambodia.com
  * Performing LDAP DSE lookup on: 10.51.0.5
  * Successfully discovered: amkdc02.amkcambodia.com
  amkdc02.amkcambodia.com
  type: kerberos
  realm-name: amkdc02.amkcambodia.com
  domain-name: amkdc02.amkcambodia.com
  configured: no
  server-software: active-directory
  client-software: sssd
  required-package: sssd-tools
  required-package: sssd
  required-package: libnss-sss
  required-package: libpam-sss
  required-package: adcli
  required-package: samba-common-bin
  ```
- Join Computer to domain
  ```
  realm join -U "User" amkdc02.amkcambodia.com
  ```
  It will prompt to input ```Password``` of the ```User``` like a below example.
  ````
   $ sudo realm join -U user1 ad1.example.com
   Password for user1: 
  ````
- Verify domain joined
  ```
  realm list
  ```
  Result would be:
  ``` 
   amkcambodia.com
     type: kerberos realm-name: AMKCAMBODIA.COM
     domain-name: amkcambodia.com 
     configured: kerberos-member 
     server-software: active-directory 
     client-software: sssd 
     required-package: sssd-tools 
     required -package: sssd 
     required-package: libnss-sss 
     required - package: libpam-sss 
     required- package: adcli
     required-package: samba-common-bin 
     login-formats: %U 
     login-policy:
   ```
- Update policy
  
  ````
   adsysctl update --all -v
  ````
  Here is the below example result:
  ````
  $ adsysctl policy update --all -v
  INFO No configuration file: Config File "adsys" Not Found in "[/home/warthogs.biz/b/bob /etc]".
  We will only use the defaults, env variables or flags. 
  INFO Apply policy for adclient04 (machine: true)  
  INFO Apply policy for bob@warthogs.biz (machine: false) 
  ````
````Note:```` Make add AD users to group before login to Ubuntu!
#### --> Completed join domain!

-------------------------------------------------------------------

## Option Auto Setup
### 1. Fresh Installation

- Install package require
  ```
  sudo apt-get install git -y
  ```
- Download configuration file from GitHub: https://github.com/amkcambodia/ubuntu-desktop.git
  ```
  git clone https://github.com/amkcambodia/ubuntu-desktop.git /tmp/ubuntu-desktop
  chmod 755 -R /tmp/ubuntu-desktop
  cd /tmp/ubuntu-desktop
  ```
- Run Install
  ```./install.sh```
  ```
  ./install.sh
  ```
  - ````Choose 1 for Fresh installation````
  - Wait for a next question
  - ```Choose 2 for Teller or Bramch Setup```

-------------------------------------------------------------------
## Opetion Manual Setup
### Manual Installation

#### 0. Create the requirement directory

`````
if [ ! -d /usr/local/bin/amk ]; then
    echo "📁 Creating /usr/local/bin/amk directory..."
    sudo mkdir -p /usr/local/bin/amk
    sudo chmod 755 /usr/local/bin/amk
else
    echo "📂 /usr/local/bin/amk already exists."
fi
`````

#### 1. Join domain
Please follow the above guide to join the domain.

#### 2. Configure SSSD

- Edit SSSD config
  ```
  sudo cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf.bk
  sudo vi /etc/sssd/sssd.conf
  ```

- Let commnand out ```#``` to configure SSSD
  ```
  #fallback_homedir = /home/%u@%d
  #access_provider = ad
  #use_fully_qualified_names = True
  ```
- Add below config to SSSD
  ```
  simple_allow_group = ubunt-group
  use_fully_qualified_names = False
  access_provider = simple
  fallback_homedir = /home/%u
  ```

#### 3. Configure PAM.D

- Backup configuration

  ```
  sudo cp /etc/pam.d/common-auth /etc/pam.d/common-auth.bak
  sudo cp /etc/pam.d/common-password /etc/pam.d/common-password.bak
  sudo cp /etc/pam.d/common-session /etc/pam.d/common-session.bak
  ```

- Configure for common-auth

  Edit ```common-auth```
    
  ```
  vi /etc/pam.d/common-auth
  ```
  Then, add below 
  ```
  auth    sufficient    pam_sss.so
  ```
- Configure for common-session
  
  Edit ```common-session```
    
  ```
  vi /etc/pam.d/common-session
  ```
  Then, add below 
  ```
  password   [success=1 default=ignore]   pam_sss.so use_authtok
  session required pam_mkhomedir.so skel=/etc/skel umask=0022
  session optional pam_exec.so /usr/local/bin/fix_dconf_profile.sh
  ```
- Configure for common-password

  Edit ```common-password```
    
  ```
  vi /etc/pam.d/common-password
  ```
  Then, add below
  ```
  password   [success=1 default=ignore]   pam_sss.so use_authtok
  ```
- Allow AD Group to map drive (without root)

  - Backup config
  ````
  sudo cp /etc/sudoers /etc/sudoers.backup.$(date +%F_%T)
  ````
  Modify sudoers by using ```` vi /etc/sudoers````
  ````
  vi /etc/sudoers
  ````
  Then add
  ````
  ubuntu-group ALL=(ALL) NOPASSWD: /usr/local/bin/amk/mount-dfs.sh
  ````
- Fix Miss Match user profile

  ````
  vi /usr/local/bin/fix_dconf_profile.sh
  ````
  Then add
  
  ````
  #!/bin/bash
  
  CONF_DIR="/etc/dconf/profile"
  
  # Only root should do this
  if [ "$(id -u)" -ne 0 ]; then
      exit 0
  fi
  
  # Loop through files with @ in the name
  for filepath in "$CONF_DIR"/*@*; do
      [ -e "$filepath" ] || continue
  
      filename=$(basename "$filepath")
      shortname="${filename%@*}"
      newpath="$CONF_DIR/$shortname"
  
      if [ ! -e "$newpath" ]; then
          mv "$filepath" "$newpath"
          echo "Renamed: $filename -> $shortname"
      fi
  done
  ````
- Update permission

  ````
  sudo chmod 755 /usr/local/bin/fix_dconf_profile.sh
  sudo chmod +x /usr/local/bin/fix_dconf_profile.sh
  ````
#### 4. Configure safe credential

- Create Directory store with limit permission
    ````
    sudo mkdir -p /etc/smbcred
    sudo chown root:ubuntu-group /etc/smbcred
    sudo chmod 1770 /etc/smbcred
    sudo mkdir -p /bin/amk
    
    ````
- Create credential prompt app

  ````
   vi /bin/amk/smbcred.sh
  ````
  Then add below script
  ````
  #!/bin/bash
  
  # Exclude user "sam"
  excluded_users=("sam")
  for u in "${excluded_users[@]}"; do
      if [ "$USER" == "$u" ]; then
          echo "User $USER is excluded from this script."
          exit 0
      fi
  done
  
  USERNAME=$(logname)  # Get real logged-in user
  CRED_DIR="/etc/smbcred"
  cred_file="$CRED_DIR/$USERNAME"
  cred_age_days=90
  test_share="//amkcambodia.com/netlogon"
  
  # # Check if running as root since /etc/smbcred needs root permissions
  # if [ "$(id -u)" -ne 0 ]; then
  #     echo "❌ This script must be run as root to access $CRED_DIR"
  #     exit 1
  # fi
  
  # Function to check if credentials file is older than X days
  is_cred_expired() {
      if [ ! -e "$cred_file" ]; then
          return 0
      fi
      last_modified=$(stat -c %Y "$cred_file")
      now=$(date +%s)
      age=$(( (now - last_modified) / 86400 ))
      [ "$age" -ge "$cred_age_days" ]
  }
  
  # Function to test current credentials using smbclient
  are_credentials_valid() {
      smbclient "$test_share" -A "$cred_file" -c "exit" &>/dev/null
      return $?
  }
  
  # Create credential directory if missing
  if [ ! -d "$CRED_DIR" ]; then
      mkdir -p "$CRED_DIR"
      chmod 700 "$CRED_DIR"
  fi
  
  # Load username and domain from credential file if exists
  if [ -f "$cred_file" ]; then
      # shellcheck disable=SC1090
      . "$cred_file"
  fi
  
  # Prompt if no file, invalid file, expired, or test fails
  if [ ! -s "$cred_file" ] || ! grep -q "password=" "$cred_file" || is_cred_expired || ! are_credentials_valid; then
      # Use zenity to prompt user for input (requires X environment)
      domain=$(zenity --entry --title="Login" --text="Enter domain:" --entry-text="${domain:-}")
      username=$(zenity --entry --title="Login" --text="Enter username:" --entry-text "${username:-}")
      password=$(zenity --password --title="Login")
  
      if [ -n "$username" ] && [ -n "$password" ]; then
          cat <<CRED > "$cred_file"
  username=$username
  password=$password
  domain=$domain
  CRED
          chmod 600 "$cred_file"
          chown "$USER":"$USER" "$cred_file"
          zenity --info --text="✅ Credentials updated successfully."
          echo "✅ Credentials updated successfully."
      else
          zenity --error --text="❌ Missing credentials. Login failed."
          echo "❌ Missing username or password. Aborted."
          exit 1
      fi
  else
      echo "✅ Credentials are valid and not expired."
  fi

  ````
- Create auto prompt password update

  ````
  vi /etc/xdg/autostart/smbcred.desktop
  ````
  Then add below script
  ````
  [Desktop Entry]
  Type=Application
  Exec=/bin/bash -c "/bin/amk/smbcred.sh >> /tmp/smbcred.log 2>&1"
  Hidden=false
  NoDisplay=false
  X-GNOME-Autostart-enabled=true
  Name=Please Update Your New Password
  Comment=Please Update Your New Password
  ````
- Create auto run check script during start session
  
  ````
  vi /usr/local/bin/amk/autostart-prompt.sh
  ````
  Then add below script
  ````
  #!/bin/bash
  
  # Log output
  LOG="/var/log/pam_exec.log"
  exec >> "$LOG" 2>&1
  
  echo "=== $(date) Starting PAM setup ==="
  
 
  # Run smbcred.sh first to make sure credentials are set
  /bin/bash /bin/amk/smbcred.sh
  
  # Configure LAN
  /bin/bash /usr/local/bin/amk/setup_lan.sh
  
  # Configure Wi-Fi
  /bin/bash /usr/local/bin/amk/wifi-setting.sh
   
  # Auto mount drive
  /bin/bash /usr/local/bin/amk/mount-dfs.sh
   
  echo "=== $(date) PAM setup complete ==="
  ````
#### 5. Configure Network
- Allow ```ubuntu-group``` to update network setting (without root)
  
  ````
  sudo tee /etc/polkit-1/rules.d/50-networkmanager-ubuntu-group.rules > /dev/null <<EOF
  polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.NetworkManager.settings.modify.system" &&
          subject.isInGroup("ubuntu-group")) {
          return polkit.Result.YES;
      }
  });
  EOF
  
  sudo systemctl restart polkit
  ````
- Configure for LAN

  - Create Network authentication:
    
    Using ```EAP-MSCHAPv2, RootCA, 802.1x, AD User``` 
  - Create script file
    ````
    sudo vi /usr/local/bin/amk/setup_lan.sh
    ````
    Then add
    ````
    #!/bin/bash
    
    CON_NAME="Wired connection 1"
    IFACE=$(nmcli -t device status | grep ':ethernet:' | cut -d: -f1)
    
    if [[ -z "$IFACE" ]]; then
      echo "❌ No Ethernet interface found."
      exit 1
    fi
    
    CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"
    CRED_FILE="/etc/smbcred/$USERNAME"
    
    if [[ ! -f "$CRED_FILE" ]]; then
      echo "❌ Credential file not found."
      exit 1
    fi
    
    source "$CRED_FILE"
    
    if [[ -z "$username" || -z "$password" ]]; then
      echo "❌ Username or password not defined."
      exit 1
    fi
    
    if [[ -n "$domain" ]]; then
      IDENTITY="$domain\\$username"
    else
      IDENTITY="$username"
    fi
    
    echo "🔧 Configuring LAN: $CON_NAME"
    #nmcli connection add type ethernet ifname "$IFACE" con-name "$CON_NAME" \
    nmcli connection "$CON_NAME" \
      802-1x.eap peap \
      802-1x.identity "$IDENTITY" \
      802-1x.password "$password" \
      802-1x.phase2-auth mschapv2 \
      802-1x.ca-cert "$CA_CERT" \
      802-1x.system-ca-certs yes \
      connection.autoconnect yes
    
    echo "✅ LAN profile '$CON_NAME' created."

    ````
  - Allow permission
    ````
    sudo chmod 755 /usr/local/bin/amk/setup_lan.sh && sudo chmod +x /usr/local/bin/amk/setup_lan.sh
    ````

- Configure for WIFI

  - Create WIFI authentication:
    
    Using ```EAP-MSCHAPv2, RootCA, 802.1x, AD User``` 
  - Create script
    ````
    sudo vi /usr/local/bin/amk/wifi-setting.sh
    ````
    Then add
    ````
    #!/bin/bash
    TARGET_SSID="AMKBr"
    IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)
  
    if [[ -z "$IFACE" ]]; then
      echo "❌ No Wi-Fi interface found."
      exit 1
    fi
  
    CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"
    CRED_FILE="/etc/smbcred/$USERNAME"
  
    if [[ ! -f "$CRED_FILE" ]]; then
      echo "❌ Credential file not found at $CRED_FILE."
      exit 1
    fi
  
    source "$CRED_FILE"
  
    if [[ -z "$username" || -z "$password" ]]; then
      echo "❌ Username or password not defined in $CRED_FILE."
      exit 1
    fi
  
    if [[ -n "$domain" ]]; then
      IDENTITY="$domain\\$username"
    else
      IDENTITY="$username"
    fi
  
    echo "🔍 Checking if connection profile exists for SSID: $TARGET_SSID..."
  
    if nmcli connection show "$TARGET_SSID" &>/dev/null; then
      echo "🔄 Modifying existing Wi-Fi connection: $TARGET_SSID"
      nmcli connection modify "$TARGET_SSID" \
        wifi-sec.key-mgmt wpa-eap \
        802-1x.eap peap \
        802-1x.identity "$IDENTITY" \
        802-1x.password "$password" \
        802-1x.phase2-auth mschapv2 \
        802-1x.ca-cert "$CA_CERT" \
        802-1x.system-ca-certs yes \
        wifi-sec.group ccmp \
        connection.autoconnect yes
    else
      echo "➕ Creating new Wi-Fi connection: $TARGET_SSID"
      nmcli connection add type wifi ifname "$IFACE" con-name "$TARGET_SSID" ssid "$TARGET_SSID" \
        wifi-sec.key-mgmt wpa-eap \
        802-1x.eap peap \
        802-1x.identity "$IDENTITY" \
        802-1x.password "$password" \
        802-1x.phase2-auth mschapv2 \
        802-1x.ca-cert "$CA_CERT" \
        802-1x.system-ca-certs yes \
        wifi-sec.group ccmp \
        connection.autoconnect yes
    fi
  
    echo "🔌 Reconnecting to $TARGET_SSID..."
    nmcli device disconnect "$IFACE"
    sleep 2
    nmcli device wifi connect "$TARGET_SSID" ifname "$IFACE"
  
    echo "✅ Wi-Fi profile configured and connected to $TARGET_SSID."
    ````
  - Allow permission
    ````
    sudo chmod 755 /usr/local/bin/amk/wifi-setting.sh && sudo chmod +x /usr/local/bin/amk/wifi-setting.sh
    ````

#### 6. Configure Map Drive 

