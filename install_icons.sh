#!/bin/sh

icons="resources/icons/"
for file in $(find $icons -type f); do
    dest="/usr/share/icons/hicolor/${file#$icons}"
    install -Dm644 "$file" "$dest"
    if [ $? -eq 0 ]; then
        echo "Installed: $dest" 
    fi
done

gtk-update-icon-cache /usr/share/icons/hicolor -f