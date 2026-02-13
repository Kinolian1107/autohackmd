#!/usr/bin/env bash
# hackmd_update.sh - Update a HackMD note
# Usage:
#   hackmd_update.sh --note-id <id> [OPTIONS]
#
# Options:
#   --read-perm <owner|signed_in|guest>
#   --write-perm <owner|signed_in|guest>
#   --content <text>
#   --file <path>
#   --permalink <slug>
#   --delete              Delete the note instead of updating
#
# Output: JSON status message

set -euo pipefail

CONFIG_DIR="${HOME}/.config/autohackmd"
CONFIG_FILE="${CONFIG_DIR}/config.json"
API_BASE="https://api.hackmd.io/v1"

NOTE_ID=""
READ_PERM=""
WRITE_PERM=""
CONTENT=""
FILE=""
PERMALINK=""
DELETE_NOTE=false

usage() {
  cat <<'EOF'
Usage: hackmd_update.sh --note-id <id> [OPTIONS]

Options:
  --note-id <id>                     Note ID (required)
  --read-perm <owner|signed_in|guest> Update read permission
  --write-perm <owner|signed_in|guest> Update write permission
  --content <text>                    Update note content
  --file <path>                       Update content from file
  --permalink <slug>                  Set permalink
  --delete                            Delete the note
  -h, --help                          Show this help message

Note: When updating permissions, both --read-perm and --write-perm
must be provided together. writePermission must be stricter than
or equal to readPermission.
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
  echo '{"status":"error","message":"No token found. Set HACKMD_API_TOKEN or run hackmd_config.sh --token <token>"}' >&2
  return 1
}

escape_json() {
  local str="$1"
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  str="${str//$'\n'/\\n}"
  str="${str//$'\r'/\\r}"
  str="${str//$'\t'/\\t}"
  echo "$str"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --note-id)
      NOTE_ID="${2:-}"
      shift 2
      ;;
    --read-perm)
      READ_PERM="${2:-}"
      shift 2
      ;;
    --write-perm)
      WRITE_PERM="${2:-}"
      shift 2
      ;;
    --content)
      CONTENT="${2:-}"
      shift 2
      ;;
    --file)
      FILE="${2:-}"
      shift 2
      ;;
    --permalink)
      PERMALINK="${2:-}"
      shift 2
      ;;
    --delete)
      DELETE_NOTE=true
      shift
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

# Validate
if [[ -z "$NOTE_ID" ]]; then
  echo '{"status":"error","message":"--note-id is required"}'
  exit 1
fi

# Get token
TOKEN=$(get_token) || exit 1

# Handle delete
if [[ "$DELETE_NOTE" == true ]]; then
  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X DELETE \
    -H "Authorization: Bearer ${TOKEN}" \
    "${API_BASE}/notes/${NOTE_ID}" 2>/dev/null) || {
    echo '{"status":"error","message":"Failed to connect to HackMD API"}'
    exit 1
  }
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  if [[ "$HTTP_CODE" == "204" ]]; then
    echo '{"status":"success","message":"Note deleted","noteId":"'"$NOTE_ID"'"}'
  else
    BODY=$(echo "$RESPONSE" | sed '$d')
    ESCAPED_BODY=$(echo "${BODY:-}" | sed 's/"/\\"/g')
    echo '{"status":"error","httpCode":"'"$HTTP_CODE"'","message":"Delete failed","details":"'"${ESCAPED_BODY:-unknown}"'"}'
    exit 1
  fi
  exit 0
fi

# Read file if provided
if [[ -n "$FILE" ]]; then
  if [[ ! -f "$FILE" ]]; then
    echo '{"status":"error","message":"File not found: '"$FILE"'"}'
    exit 1
  fi
  CONTENT=$(cat "$FILE")
fi

# Build JSON body
JSON_PARTS=()
if [[ -n "$CONTENT" ]]; then
  ESCAPED=$(escape_json "$CONTENT")
  JSON_PARTS+=("\"content\":\"$ESCAPED\"")
fi
if [[ -n "$READ_PERM" ]]; then
  JSON_PARTS+=("\"readPermission\":\"$READ_PERM\"")
fi
if [[ -n "$WRITE_PERM" ]]; then
  JSON_PARTS+=("\"writePermission\":\"$WRITE_PERM\"")
fi
if [[ -n "$PERMALINK" ]]; then
  JSON_PARTS+=("\"permalink\":\"$PERMALINK\"")
fi

if [[ ${#JSON_PARTS[@]} -eq 0 ]]; then
  echo '{"status":"error","message":"No update fields provided. Use --content, --read-perm, --write-perm, or --permalink"}'
  exit 1
fi

# Join JSON parts
JSON_BODY="{"
for i in "${!JSON_PARTS[@]}"; do
  [[ $i -gt 0 ]] && JSON_BODY+=","
  JSON_BODY+="${JSON_PARTS[$i]}"
done
JSON_BODY+="}"

# Send update request
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X PATCH \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$JSON_BODY" \
  "${API_BASE}/notes/${NOTE_ID}" 2>/dev/null) || {
  echo '{"status":"error","message":"Failed to connect to HackMD API"}'
  exit 1
}

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" == "202" ]]; then
  echo '{"status":"success","message":"Note updated","noteId":"'"$NOTE_ID"'"}'
else
  ESCAPED_BODY=$(echo "${BODY:-}" | sed 's/"/\\"/g')
  echo '{"status":"error","httpCode":"'"$HTTP_CODE"'","message":"Update failed","details":"'"${ESCAPED_BODY:-unknown}"'"}'
  exit 1
fi
