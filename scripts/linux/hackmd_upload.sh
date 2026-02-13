#!/usr/bin/env bash
# hackmd_upload.sh - Upload markdown to HackMD
# Usage:
#   hackmd_upload.sh --file <path> [--tags tag1,tag2]
#   hackmd_upload.sh --title "title" --content "content" [--tags tag1,tag2]
#
# Output: JSON { "noteId", "publishLink", "shortId", "title" }

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config/autohackmd"
CONFIG_FILE="${CONFIG_DIR}/config.json"
API_BASE="https://api.hackmd.io/v1"

FILE=""
TITLE=""
CONTENT=""
TAGS=""

usage() {
  cat <<'EOF'
Usage: hackmd_upload.sh [OPTIONS]

Options:
  --file <path>       Upload from markdown file
  --title <title>     Note title (used with --content)
  --content <text>    Note content as string
  --tags <t1,t2>      Comma-separated tags to embed in note
  -h, --help          Show this help message

Output: JSON with noteId, publishLink, shortId, title

Permissions are set to:
  - readPermission: guest (everyone can read)
  - writePermission: owner (only you can edit)
EOF
  exit 0
}

get_token() {
  if [[ -n "${HACKMD_API_TOKEN:-}" ]]; then
    echo "$HACKMD_API_TOKEN"
    return 0
  fi
  if [[ -f "$CONFIG_FILE" ]]; then
    local token
    if command -v jq &>/dev/null; then
      token=$(jq -r '.api_token // empty' "$CONFIG_FILE" 2>/dev/null)
    else
      token=$(grep -o '"api_token"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" 2>/dev/null | sed 's/.*"api_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi
    if [[ -n "$token" ]]; then
      echo "$token"
      return 0
    fi
  fi
  echo '{"status":"error","message":"No token found. Set HACKMD_API_TOKEN env var or run: hackmd_config.sh --token <your-token>"}' >&2
  return 1
}

escape_json() {
  # Escape string for JSON embedding
  local str="$1"
  str="${str//\\/\\\\}"    # backslash
  str="${str//\"/\\\"}"    # double quote
  str="${str//$'\n'/\\n}"  # newline
  str="${str//$'\r'/\\r}"  # carriage return
  str="${str//$'\t'/\\t}"  # tab
  echo "$str"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      FILE="${2:-}"
      [[ -z "$FILE" ]] && { echo '{"status":"error","message":"--file requires a path"}'; exit 1; }
      shift 2
      ;;
    --title)
      TITLE="${2:-}"
      [[ -z "$TITLE" ]] && { echo '{"status":"error","message":"--title requires a value"}'; exit 1; }
      shift 2
      ;;
    --content)
      CONTENT="${2:-}"
      [[ -z "$CONTENT" ]] && { echo '{"status":"error","message":"--content requires a value"}'; exit 1; }
      shift 2
      ;;
    --tags)
      TAGS="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo '{"status":"error","message":"Unknown option: '"$1"'"}'
      exit 1
      ;;
  esac
done

# Validate input
if [[ -z "$FILE" && -z "$CONTENT" ]]; then
  echo '{"status":"error","message":"Either --file or --content is required"}'
  exit 1
fi

# Read file content
if [[ -n "$FILE" ]]; then
  if [[ ! -f "$FILE" ]]; then
    echo '{"status":"error","message":"File not found: '"$FILE"'"}'
    exit 1
  fi
  CONTENT=$(cat "$FILE")
  # Extract title from H1 header if not provided
  if [[ -z "$TITLE" ]]; then
    TITLE=$(echo "$CONTENT" | grep -m1 '^# ' | sed 's/^# //' || true)
    [[ -z "$TITLE" ]] && TITLE=$(basename "$FILE" .md)
  fi
fi

# Prepend tags to content if provided
if [[ -n "$TAGS" ]]; then
  # Convert comma-separated tags to HackMD format: ###### tags: `tag1` `tag2`
  local_tags=""
  IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
  for tag in "${TAG_ARRAY[@]}"; do
    tag=$(echo "$tag" | xargs) # trim whitespace
    local_tags="${local_tags}\`${tag}\` "
  done
  # Check if content already has tags line
  if ! echo "$CONTENT" | grep -q '^###### tags:'; then
    # Insert tags after the first H1 line, or at the top
    if echo "$CONTENT" | grep -q '^# '; then
      CONTENT=$(echo "$CONTENT" | sed "0,/^# .*/a\\
###### tags: ${local_tags}" )
    else
      CONTENT="###### tags: ${local_tags}
${CONTENT}"
    fi
  fi
fi

# Get token
TOKEN=$(get_token) || exit 1

# Escape content for JSON
ESCAPED_CONTENT=$(escape_json "$CONTENT")
ESCAPED_TITLE=$(escape_json "$TITLE")

# Build JSON body
JSON_BODY='{
  "title": "'"$ESCAPED_TITLE"'",
  "content": "'"$ESCAPED_CONTENT"'",
  "readPermission": "guest",
  "writePermission": "owner",
  "commentPermission": "everyone"
}'

# Upload to HackMD
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$JSON_BODY" \
  "${API_BASE}/notes" 2>/dev/null) || {
  echo '{"status":"error","message":"Failed to connect to HackMD API"}'
  exit 1
}

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "201" ]]; then
  # Extract fields from response
  if command -v jq &>/dev/null; then
    NOTE_ID=$(echo "$BODY" | jq -r '.id')
    PUBLISH_LINK=$(echo "$BODY" | jq -r '.publishLink')
    SHORT_ID=$(echo "$BODY" | jq -r '.shortId')
    NOTE_TITLE=$(echo "$BODY" | jq -r '.title')
  else
    NOTE_ID=$(echo "$BODY" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
    PUBLISH_LINK=$(echo "$BODY" | grep -o '"publishLink"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')
    SHORT_ID=$(echo "$BODY" | grep -o '"shortId"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')
    NOTE_TITLE=$(echo "$BODY" | grep -o '"title"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
  fi
  echo '{"status":"success","noteId":"'"$NOTE_ID"'","publishLink":"'"$PUBLISH_LINK"'","shortId":"'"$SHORT_ID"'","title":"'"$NOTE_TITLE"'"}'
else
  ESCAPED_BODY=$(echo "$BODY" | sed 's/"/\\"/g')
  echo '{"status":"error","httpCode":"'"$HTTP_CODE"'","message":"Upload failed","details":"'"$ESCAPED_BODY"'"}'
  exit 1
fi
