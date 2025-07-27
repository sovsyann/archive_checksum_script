#!/bin/bash

# ✅ Force UTF-8 handling for filenames with special characters
export LC_ALL=en_US.utf8
export LANG=en_US.utf8

# 🆘 Show usage help
show_help() {
  echo ""
  echo "Usage: $0 [checklist_file] [root_folder]"
  echo ""
  echo "Verifies file integrity using an MD5 checklist."
  echo ""
  echo "Arguments:"
  echo "  checklist_file   Path to checklist.md5sum (optional, default: ./checklist.md5sum)"
  echo "  root_folder      Path to root folder to verify (optional, default: ./)"
  echo ""
  echo "Examples:"
  echo "  $0"
  echo "  $0 /media/dvd/checklist.md5sum"
  echo "  $0 ./checklist.md5sum /media/dvd/myfolder"
  echo ""
  exit 1
}

# 🧠 Handle help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  show_help
fi

# 🧩 Parse input arguments
CHECKLIST_FILE="${1:-checklist.md5sum}"
ROOT_FOLDER="${2:-.}"

# ✅ Validate checklist file
if [ ! -f "$CHECKLIST_FILE" ]; then
  echo "❌ Error: Checklist file not found: $CHECKLIST_FILE"
  exit 1
fi

# ✅ Validate root folder
if [ ! -d "$ROOT_FOLDER" ]; then
  echo "❌ Error: Root folder not found: $ROOT_FOLDER"
  exit 1
fi

# 🧠 Detect platform for hash command
if command -v md5 > /dev/null; then
  IS_MAC=true
else
  IS_MAC=false
fi

echo "🔍 Verifying files using MD5..."
echo "📄 Checklist file : $CHECKLIST_FILE"
echo "📁 Root folder    : $ROOT_FOLDER"
echo "INFO: Watch the progress. Errors are printed immediately and summarized in the report."
echo ""

TOTAL=$(wc -l < "$CHECKLIST_FILE")
i=0
failures=0
missing=0
pad_total=$(printf "%04d" "$TOTAL")

# Store failed files
declare -a missing_files
declare -a bad_hash_files

while IFS= read -r line || [ -n "$line" ]; do
  ((i++))
  pad_i=$(printf "%04d" "$i")

  expected_hash="${line:0:32}"
  rel_path="${line:34}"
  rel_path="$(echo "$rel_path" | sed 's/^[[:space:]]*//')"

  full_path="$ROOT_FOLDER/$rel_path"

  echo -ne "\033[1K\r[ $pad_i / $pad_total ]...${full_path: -54}"
  
if [ ! -f "$full_path" ]; then
    missing_files+=("$rel_path")
    ((failures++))
    ((missing++))
    echo -ne "\033[1K\rERROR File missing: $full_path \n" 
    continue
  fi

  if [ "$IS_MAC" = true ]; then
    actual_hash=$(md5 -q "$full_path") || actual_hash=""
  else
    actual_hash=$(md5sum "$full_path" | awk '{print $1}') || actual_hash=""
  fi

  if [ "$actual_hash" != "$expected_hash" ]; then
    echo -ne "\033[1K\rERROR Hash mismatch for: $full_path \n"
    bad_hash_files+=("$rel_path")
    ((failures++))
  fi
done < "$CHECKLIST_FILE"

echo -ne "\n\n"

# 📊 Summary
echo "✅ Report SUMMARY for MD5 Check:"
echo "Total files listed : $TOTAL"
echo "✅ Passed           : $((TOTAL - failures))"
echo "❌ Missing files    : $missing"
echo "❌ Hash mismatches  : $((failures - missing))"
echo ""
echo "📊 DETAILED report:" 

# 📂 Show failures
if [ "${#missing_files[@]}" -gt 0 ]; then
  echo "📂 Missing files:"
  for f in "${missing_files[@]}"; do
    echo " - $f"
  done
  echo
fi

if [ "${#bad_hash_files[@]}" -gt 0 ]; then
  echo "⚠️  Hash mismatched files:"
  for f in "${bad_hash_files[@]}"; do
    echo " - $f"
  done
  echo
fi
