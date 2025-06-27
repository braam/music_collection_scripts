#!/bin/bash

# Root directory to scan
ROOT_DIR="/music"

# File patterns to search for
PATTERNS=("album.nfo" "artist.nfo")

# Variable to count total matches
total_found=0

echo "🔍 Dry-run: scanning for the following files in subdirectories of '$ROOT_DIR':"
echo

# Dry-run: list matching files and count them
for pattern in "${PATTERNS[@]}"; do
    echo "📄 Looking for '$pattern':"
    matches=$(find "$ROOT_DIR" -mindepth 2 -type f -name "$pattern")
    if [[ -z "$matches" ]]; then
        echo "→ 0 files found"
    else
        echo "$matches"
        count=$(echo "$matches" | wc -l)
        total_found=$((total_found + count))
    fi
    echo
done

# Exit if nothing was found
if [[ "$total_found" -eq 0 ]]; then
    echo "✅ No matching files found. Nothing to delete."
    exit 0
fi

# Ask for confirmation
read -p "⚠️  Do you want to delete these $total_found file(s)? (y/N): " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo
    echo "🗑️  Deleting files..."
    for pattern in "${PATTERNS[@]}"; do
        find "$ROOT_DIR" -mindepth 2 -type f -name "$pattern" -delete
    done
    echo "✅ Files deleted."
else
    echo "❌ Deletion canceled."
fi