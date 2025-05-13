#!/bin/bash
set -e

# Get repo root relative to this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CSV_FILE="$REPO_ROOT/inc_file_to_sync/dev_to_uat.csv"

echo "🔄 Starting sync from CSV"

if [ ! -f "$CSV_FILE" ]; then
  echo "❌ CSV file not found: $CSV_FILE"
  exit 1
fi

echo "✅ CSV file found: $CSV_FILE"

# Prepare temp files
TABLE_FILES=$(mktemp)
EXT_FILES=$(mktemp)

# Extract paths
tail -n +2 "$CSV_FILE" | awk -F',' '$1=="table" { print $2 }' > "$TABLE_FILES"
tail -n +2 "$CSV_FILE" | awk -F',' '$1=="external" { print $2 }' > "$EXT_FILES"

# Sync tables
echo "📂 Syncing table files:"
cat "$TABLE_FILES"
rsync -avc --inplace --no-perms \
  --files-from="$TABLE_FILES" \
  "$REPO_ROOT/dev/" \
  "$REPO_ROOT/uat/"

# Sync external tables
echo "📂 Syncing external table files:"
cat "$EXT_FILES"
rsync -avc --inplace --no-perms \
  --files-from="$EXT_FILES" \
  "$REPO_ROOT/dev/" \
  "$REPO_ROOT/uat/"

# Cleanup
rm "$TABLE_FILES" "$EXT_FILES"

echo "✅ Sync completed successfully"
