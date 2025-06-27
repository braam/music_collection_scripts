#!/bin/bash

# Base directory to search
BASE_DIR="/music"

# File extensions to check (adjust as needed)
EXTENSIONS=("mp3" "m4a" "flac" "ogg")

for ext in "${EXTENSIONS[@]}"; do
  # Find all files with this extension recursively
  find "$BASE_DIR" -type f -iname "*.${ext}" | while read -r file; do
    # Check ffmpeg output for attached pictures
    if ffmpeg -i "$file" 2>&1 | grep -q "attached pic"; then
      echo "Embedded art found in: $file"
    fi
  done
done