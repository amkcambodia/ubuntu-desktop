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
