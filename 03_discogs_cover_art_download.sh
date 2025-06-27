#!/bin/bash

# 🚨 Discogs API Token
DISCOGS_TOKEN="xxxxxxxxxxxxxxxxxxxxxxx"

# ✅ Check dependencies
if ! command -v jq &>/dev/null; then
  echo "Missing dependency: jq"
  exit 1
fi

# ➕ Helper: URL encode using jq
urlencode() {
  jq -rn --arg v "$1" '$v|@uri'
}

# 📥 Check folder input
TARGET_DIR="$1"
if [ ! -d "$TARGET_DIR" ]; then
  echo "Usage: $0 /path/to/album-folder"
  exit 1
fi

# 🧱 Get folder name
folder=$(basename "$TARGET_DIR")

# 📦 Default values
artist=""
album=""
year=""

# 🧠 Detect format:
# Format 1: Artist - [YYYY] - Album
regex1='^(.+)[[:space:]]+-[[:space:]]+\[([0-9]{4})\][[:space:]]+-[[:space:]]+(.+)$'
# Format 2: Album [YYYY]
regex2='^(.+)[[:space:]]+\[([0-9]{4})\]$'

if [[ "$folder" =~ $regex1 ]]; then
  artist=$(echo "${BASH_REMATCH[1]}" | xargs)
  year="${BASH_REMATCH[2]}"
  album=$(echo "${BASH_REMATCH[3]}" | xargs)
elif [[ "$folder" =~ $regex2 ]]; then
  artist=""
  album=$(echo "${BASH_REMATCH[1]}" | xargs)
  year="${BASH_REMATCH[2]}"
else
  echo "❌ Unsupported folder name format: $folder"
  echo "   Expected formats:"
  echo "     - Artist - [year] - Album"
  echo "     - Album [year]"
  exit 1
fi

# 📄 Show parsed info
echo "🔍 Searching Discogs for:"
[ -n "$artist" ] && echo "   Artist: $artist"
echo "   Album : $album"
[ -n "$year" ] && echo "   Year  : $year"

# 🌐 Build Discogs query (with proper encoding)
artist_encoded=$(urlencode "$artist")
album_encoded=$(urlencode "$album")

query="https://api.discogs.com/database/search?token=$DISCOGS_TOKEN&type=release&format=CD&format=Album&has_image=true&per_page=1"
[ -n "$artist" ] && query="$query&artist=$artist_encoded"
query="$query&release_title=$album_encoded"

# 🌐 Call Discogs
response=$(curl -s "$query")

# 🖼 Extract cover image URL
cover_url=$(echo "$response" | jq -r '.results[0].cover_image')

if [[ "$cover_url" == "null" || -z "$cover_url" ]]; then
  echo "❌ No cover image found on Discogs."
  exit 1
fi

# 💾 Download image
output="$TARGET_DIR/cover.jpg"
curl -s -L "$cover_url" -o "$output"

if [ -f "$output" ]; then
  echo "✅ Cover downloaded to: $output"
else
  echo "❌ Failed to download cover image."
fi