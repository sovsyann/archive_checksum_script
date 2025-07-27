#!/bin/bash

set -e

# Usage check
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <target-folder>"
  exit 1
fi

TARGET_DIR="$1"
OUTFILE="checklist.md5sum"

# Ensure target is a directory
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: '$TARGET_DIR' is not a directory"
  exit 1
fi

# Determine platform
IS_MAC=false
if [[ "$(uname)" == "Darwin" ]]; then
  IS_MAC=true
fi

# Normalize path and extract base folder name
TARGET_DIR_ABS="$(cd "$TARGET_DIR" && pwd)"
BASE_FOLDER="$(basename "$TARGET_DIR_ABS")"

OUTFILE_PATH="$(pwd)/$OUTFILE"
> "$OUTFILE_PATH"

echo "🔍 Generating MD5 checklist for: $TARGET_DIR_ABS"
echo "💾 Output will be: $OUTFILE_PATH"
echo

# Find files, skipping macOS/system trash
find "$TARGET_DIR_ABS" -type f \
  ! -name "._*" \
  ! -name ".DS_Store" \
  ! -name "desktop.ini" \
  -print0 |
while IFS= read -r -d '' file; do
    rel_path="$BASE_FOLDER/${file#$TARGET_DIR_ABS/}"

    if $IS_MAC; then
        # Normalize to NFC on macOS
        norm_path=$(iconv -f UTF-8-MAC -t UTF-8 <<< "$rel_path")
    else
        # On Linux, assume filenames are already NFC
        norm_path="$rel_path"
    fi

    # Compute hash
    if $IS_MAC; then
        hash=$(md5 -q "$file")
    else
        hash=$(md5sum "$file" | awk '{print $1}')
    fi

    printf "%s  %s\n" "$hash" "$norm_path" >> "$OUTFILE_PATH"
done

echo "✅ MD5 checklist written to $OUTFILE_PATH"

