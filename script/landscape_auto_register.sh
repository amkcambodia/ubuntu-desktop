#!/bin/bash

#Install software
add-apt-repository ppa:landscape/self-hosted-24.04 -y
#apt install landscape-client -y
DEBIAN_FRONTEND=noninteractive apt install -y landscape-client
systemctl restart landscape-client.service

# Get the current hostname
COMPUTER_TITLE=$(hostname)

# Configuration parameters
ACCOUNT_NAME="standalone"
LANDSCAPE_URL="https://uat-landscape.amkcambodia.com/message-system"
PING_URL="http://uat-landscape.amkcambodia.com/ping"
SSL_CERT="/etc/ssl/certs/CACert.pem"
REGISTRATION_KEY=""  # Insert your actual key

echo "Starting landscape-config with hostname: $COMPUTER_TITLE"

# Run landscape-config with here-document to simulate ENTER inputs
sudo landscape-config \
  --computer-title "$COMPUTER_TITLE" \
  --account-name "$ACCOUNT_NAME" \
  --url "$LANDSCAPE_URL" \
  --ping-url "$PING_URL" \
  --ssl-public-key="$SSL_CERT" \
  --registration-key="$REGISTRATION_KEY" <<EOF

# Press ENTER for HTTP proxy URL
# Press ENTER for HTTPS proxy URL
y
EOF

echo "landscape-client registered successfully as $COMPUTER_TITLE"