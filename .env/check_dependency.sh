#!/bin/bash

if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo "❌ Requirements file not found: $REQUIREMENTS_FILE"
    exit 1
fi

echo "==== Installing required packages ===="

while IFS= read -r package || [ -n "$package" ]; do
    if dpkg -s "$package" >/dev/null 2>&1; then
        echo "✅ $package is already installed."
    else
        echo "📦 Installing $package..."
        if sudo apt install -y "$package"; then
            echo "✅ $package installed successfully."
        else
            echo "❌ Failed to install $package"
        fi
    fi
done < "$REQUIREMENTS_FILE"