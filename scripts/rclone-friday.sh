#!/bin/bash
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/sbin:/usr/sbin"

LOGDIR="$HOME/.rclone"
LOGFILE="$LOGDIR/icloud-sync.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Create log directory if needed
mkdir -p "$LOGDIR"

# Clear old log
[ -f "$LOGFILE" ] && rm "$LOGFILE"

echo "[$TIMESTAMP] Starting sync..." | tee -a "$LOGFILE"

# 🧯 Abort if on battery power
POWER_SOURCE=$(pmset -g batt | grep "Now drawing from" | awk '{print $4}' | tr -d '"')
if [ "$POWER_SOURCE" == "Battery" ]; then
  echo "[$(date "+%H:%M:%S")] ⚠️  Skipping sync: running on battery." | tee -a "$LOGFILE"
  exit 0
fi

# 🌐 Abort if no network
if ! /sbin/ping -q -c 1 -W 2 google.com >/dev/null; then
  echo "[$(date "+%H:%M:%S")] ⚠️  Skipping sync: no internet connection." | tee -a "$LOGFILE"
  exit 0
fi

# Folders to sync
FOLDERS=(
  "Desktop"
  "Documents"
  "Downloads"
  "Movies"
  "Music"
  "Pictures"
  "Public"
  "Saved from Chrome"
  "Support"
  "Templates"
)

ANY_FAILURE=0

for FOLDER in "${FOLDERS[@]}"; do
  echo "[$(date "+%H:%M:%S")] Syncing $FOLDER..." | tee -a "$LOGFILE"
  
  SRC="$HOME/$FOLDER"
  DEST="$HOME/Library/Mobile Documents/com~apple~CloudDocs/$FOLDER"

  mkdir -p "$SRC"
  mkdir -p "$DEST"

  rsync -av --delete "$SRC/" "$DEST/" >> "$LOGFILE" 2>&1

  if [ $? -eq 0 ]; then
    echo "[$(date "+%H:%M:%S")] ✅ $FOLDER sync complete." | tee -a "$LOGFILE"
  else
    echo "[$(date "+%H:%M:%S")] ❌ $FOLDER sync failed!" | tee -a "$LOGFILE"
    ANY_FAILURE=1
  fi
done

if [ "$ANY_FAILURE" -eq 0 ]; then
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] ✅ All sync tasks finished successfully." | tee -a "$LOGFILE"
else
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] ❌ One or more sync tasks failed!" | tee -a "$LOGFILE" >&2
  exit 1
fi
