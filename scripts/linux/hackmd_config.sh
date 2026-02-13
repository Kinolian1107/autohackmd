#!/usr/bin/env bash
# hackmd_config.sh - Configure HackMD API Token
# Usage:
#   hackmd_config.sh --token <token>       # Set token
#   hackmd_config.sh --verify              # Verify stored token
#   hackmd_config.sh --show                # Show current config path
#   hackmd_config.sh --remove              # Remove stored token

set -euo pipefail

CONFIG_DIR="${HOME}/.config/autohackmd"
CONFIG_FILE="${CONFIG_DIR}/config.json"
API_BASE="https://api.hackmd.io/v1"

usage() {
  cat <<'EOF'
Usage: hackmd_config.sh [OPTIONS]

Options:
  --token <token>   Save HackMD API token to config
  --verify          Verify the stored or env token is valid
  --show            Show config file path and status
  --remove          Remove stored token
  -h, --help        Show this help message

Token priority:
  1. $HACKMD_API_TOKEN environment variable
  2. ~/.config/autohackmd/config.json

Get your token from: https://hackmd.io/settings#api
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
    # Parse JSON without jq dependency - fallback to grep/sed
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
  return 1
}

save_token() {
  local token="$1"
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<JSONEOF
{
  "api_token": "${token}"
}
JSONEOF
  chmod 600 "$CONFIG_FILE"
  echo '{"status":"success","message":"Token saved to '"$CONFIG_FILE"'","config_path":"'"$CONFIG_FILE"'"}'
}

verify_token() {
  local token
  token=$(get_token) || {
    echo '{"status":"error","message":"No token found. Set HACKMD_API_TOKEN env var or run: hackmd_config.sh --token <your-token>"}'
    exit 1
  }

  local response http_code body
  response=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer ${token}" \
    "${API_BASE}/me" 2>/dev/null) || {
    echo '{"status":"error","message":"Failed to connect to HackMD API"}'
    exit 1
  }

  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')

  if [[ "$http_code" == "200" ]]; then
    local name=""
    if command -v jq &>/dev/null; then
      name=$(echo "$body" | jq -r '.name // "unknown"' 2>/dev/null)
    else
      name=$(echo "$body" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi
    echo '{"status":"success","message":"Token is valid","user":"'"$name"'"}'
  else
    local escaped_body
    escaped_body=$(echo "$body" | sed 's/"/\\"/g')
    echo '{"status":"error","message":"Token is invalid (HTTP '"$http_code"')","details":"'"$escaped_body"'"}'
    exit 1
  fi
}

show_config() {
  local token_source="none"
  if [[ -n "${HACKMD_API_TOKEN:-}" ]]; then
    token_source="environment"
  elif [[ -f "$CONFIG_FILE" ]]; then
    token_source="config_file"
  fi
  echo '{"config_path":"'"$CONFIG_FILE"'","token_source":"'"$token_source"'","config_exists":'$([[ -f "$CONFIG_FILE" ]] && echo true || echo false)'}'
}

remove_token() {
  if [[ -f "$CONFIG_FILE" ]]; then
    rm -f "$CONFIG_FILE"
    echo '{"status":"success","message":"Token removed from '"$CONFIG_FILE"'"}'
  else
    echo '{"status":"info","message":"No config file found at '"$CONFIG_FILE"'"}'
  fi
}

# Main
[[ $# -eq 0 ]] && usage

case "${1:-}" in
  --token)
    [[ -z "${2:-}" ]] && { echo '{"status":"error","message":"Token value required"}'; exit 1; }
    save_token "$2"
    ;;
  --verify)
    verify_token
    ;;
  --show)
    show_config
    ;;
  --remove)
    remove_token
    ;;
  -h|--help)
    usage
    ;;
  *)
    echo '{"status":"error","message":"Unknown option: '"$1"'. Use --help for usage."}'
    exit 1
    ;;
esac
