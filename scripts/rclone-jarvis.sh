#!/bin/bash

# Set Nextcloud Remote and Local Sync Path
NEXTCLOUD_DIR="nextcloud:" 
LOCAL_BASE_DIR="/home/itguyeric/"

# Directories to Sync
SYNC_DIRS=("Desktop" "Documents" "Downloads" "Movies" "Music" "Pictures" "Public" "Support" "Templates" "Videos")

# Log File
LOG_FILE="/home/itguyeric/rclone_sync.log"

# Sync each directory
for DIR in "${SYNC_DIRS[@]}"; do
  LOCAL_PATH="$LOCAL_BASE_DIR/$DIR"
  REMOTE_PATH="$NEXTCLOUD_DIR/$DIR"

  echo "$(date): Starting sync for $DIR" >> "$LOG_FILE"
  rclone bisync "$LOCAL_PATH" "$REMOTE_PATH" --log-file="$LOG_FILE" --log-level INFO --resync --copy-links --checksum

  if [ $? -eq 0 ]; then
    echo "$(date): Sync for $DIR completed successfully." >> "$LOG_FILE"
  else
    echo "$(date): Sync for $DIR encountered errors." >> "$LOG_FILE"
  fi
done
