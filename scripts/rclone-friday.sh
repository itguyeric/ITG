#!/bin/bash

# Define directories
ICLOUD_BASE_DIR="/Users/ehendricks/Library/Mobile Documents/com~apple~CloudDocs"
TARGETS=("nextcloud:" "gDrive-EH:")
## TODO: Add in seafile

# List of directories to sync
SYNC_DIRS=("Desktop" "Documents" "Downloads" "Movies" "Music" "Pictures" "Public" "Support" "Templates" "Videos")

# Log file location
LOG_FILE="/Users/ehendricks/tmp/rclone.log"

# Sync loop
for dir in "${SYNC_DIRS[@]}"; do
  SOURCE_PATH="${ICLOUD_BASE_DIR}/${dir}"
  
  for target in "${TARGETS[@]}"; do
    #/opt/homebrew/bin/rclone bisync "$SOURCE_PATH" "$target/${dir}" --log-file="$LOG_FILE" --log-level INFO --resync --copy-links --checksum
    /opt/homebrew/bin/rclone sync "$SOURCE_PATH" "$target/${dir}" --log-file="$LOG_FILE" --log-level INFO --resync --copy-links --checksum
  done
done
