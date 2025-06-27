#!/bin/bash

set -e
shopt -s nullglob
shopt -s globstar

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 \"/music/folder_pattern*\""
  exit 1
fi

for pattern in "$@"; do
  for TARGET_DIR in $pattern; do
    [ -d "$TARGET_DIR" ] || continue

    folder=$(basename "$TARGET_DIR")
    artist="Unknown Artist"
    album=""
    year=""

    # Extract year from [YYYY]
    if [[ $folder =~ \[(19|20)[0-9]{2}\] ]]; then
      year="${BASH_REMATCH[0]}"
      year="${year:1:4}"
    fi

    # Format A: Artist - [Year] - Album
    regex_a='^(.+)[[:space:]]+-[[:space:]]+\[[0-9]{4}\][[:space:]]+-[[:space:]]+(.+)$'

    # Format B: Album [Year]
    regex_b='^(.+)[[:space:]]+\[[0-9]{4}\]$'

    if [[ $folder =~ $regex_a ]]; then
      artist="${BASH_REMATCH[1]}"
      album="${BASH_REMATCH[2]}"
    elif [[ $folder =~ $regex_b ]]; then
      album="${BASH_REMATCH[1]}"
    else
      # Fallback: use foldername without [YYYY]
      album=$(echo "$folder" | sed -E 's/\[[0-9]{4}\]//g')
    fi

    # Clean up artist/album strings
    artist=$(echo "$artist" | sed -E 's/ *-+ */-/g; s/^ *//; s/ *$//')
    album=$(echo "$album" | sed -E 's/ *-+ */-/g; s/^ *//; s/ *$//')

    echo "📁 Processing: $folder"
    echo "   → Artist: $artist"
    echo "   → Album : $album"
    [ -n "$year" ] && echo "   → Year  : $year" || echo "   → Year  : (not found)"

    CLEAN_DIR="$TARGET_DIR/CLEAN"
    rm -rf "$CLEAN_DIR"
    mkdir -p "$CLEAN_DIR"

    mapfile -d '' mp3files < <(find "$TARGET_DIR" -type f -iname '*.mp3' -print0)

    if [ ${#mp3files[@]} -eq 0 ]; then
      echo "No mp3 files found in $TARGET_DIR"
      continue
    fi

    for file in "${mp3files[@]}"; do
      filename="$(basename "$file")"
      clean_file="$CLEAN_DIR/$filename"

      # Extract title and track number
      if [[ "$filename" =~ ^([0-9]{1,2})[[:space:]]*-[[:space:]]*(.+)\.mp3$ ]]; then
        track="${BASH_REMATCH[1]}"
        title="${BASH_REMATCH[2]}"
      else
        track=""
        title="${filename%.mp3}"
      fi

      # Check if artist tag exists using ffprobe
      existing_artist=$(ffprobe -v error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$file")

      # Build ffmpeg metadata options dynamically
      metadata_args=(
        -metadata title="$title"
        -metadata track="$track"
        -metadata album="$album"
        -metadata date="$year"
      )

      if [ -z "$existing_artist" ]; then
        metadata_args+=("-metadata" "artist=$artist")
        echo "🎧 Adding missing artist tag: $artist"
      else
        echo "🎧 Artist tag exists: $existing_artist"
      fi

      echo "🎧 Converting & tagging: $filename"
      ffmpeg -loglevel error -i "$file" -map 0 -map -0:v -c:a copy "${metadata_args[@]}" "$clean_file"
    done

    echo "🧹 Removing original files..."
    for file in "${mp3files[@]}"; do
      rm -f "$file"
    done

    echo "📤 Moving cleaned files back to $TARGET_DIR..."
    cp -a "$CLEAN_DIR/." "$TARGET_DIR/"
    rm -rf "$CLEAN_DIR"

    echo "✅ Done with: $TARGET_DIR"
    echo "--------------------------------------"
  done
done