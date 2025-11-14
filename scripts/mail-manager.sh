#!/bin/bash
set -euo pipefail

# Secure .env loading function
load_env_safe() {
    local env_file="${1:-.env}"
    if [ ! -f "$env_file" ]; then
        echo "ERROR: .env file not found"
        echo "Please run this script from the homeserver-quickstart directory"
        return 1
    fi
    # Parse only valid KEY=VALUE lines, ignore comments and invalid syntax
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        # Match valid variable assignment (KEY=VALUE)
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
        fi
    done < "$env_file"
}

# Load environment variables
load_env_safe .env || exit 1

# Validate required environment variables
if [ -z "${MAIL_API_TOKEN:-}" ]; then
    echo "ERROR: MAIL_API_TOKEN not set in .env file"
    echo "Please generate secrets first: ./scripts/00-generate-secrets.sh"
    exit 1
fi

# Check if argument provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 {add-domain|add-mailbox|list-mailboxes|stats} [args]"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "ERROR: jq not installed"
    echo "Install: sudo apt install jq"
    exit 1
fi

API_URL="${MAIL_API_URL:-https://mail-api.homeserver.local/api}"
API_TOKEN="${MAIL_API_TOKEN}"

# Validate domain format (basic RFC check)
validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]]; then
        echo "ERROR: Invalid domain format: $domain"
        return 1
    fi
    return 0
}

# Validate email format
validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "ERROR: Invalid email format: $email"
        return 1
    fi
    return 0
}

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    
    if [ -z "$data" ]; then
        curl -fsSL -X "$method" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            "$API_URL/$endpoint"
    else
        curl -fsSL -X "$method" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$API_URL/$endpoint"
    fi
}

case "${1:-}" in
    "add-domain")
        if [ -z "${2:-}" ]; then
            echo "ERROR: Domain name required"
            echo "Usage: $0 add-domain <domain>"
            exit 1
        fi
        validate_domain "$2" || exit 1
        echo "Adding domain: $2"
        DATA=$(jq -n --arg domain "$2" '{domain: $domain}')
        api_call POST "domains" "$DATA"
        ;;
    "add-mailbox")
        if [ -z "${2:-}" ] || [ -z "${3:-}" ] || [ -z "${4:-}" ]; then
            echo "ERROR: Missing required arguments"
            echo "Usage: $0 add-mailbox <username> <domain> <password> [quota_mb]"
            exit 1
        fi
        validate_domain "$3" || exit 1
        EMAIL="$2@$3"
        validate_email "$EMAIL" || exit 1
        
        QUOTA_MB="${5:-1000}"
        if [[ ! "$QUOTA_MB" =~ ^[0-9]+$ ]]; then
            echo "ERROR: Invalid quota (must be numeric): $QUOTA_MB"
            exit 1
        fi
        QUOTA_BYTES=$((QUOTA_MB * 1048576))
        
        echo "Creating mailbox: $EMAIL"
        DATA=$(jq -n --arg email "$2" --arg domain "$3" --arg password "$4" --argjson quota "$QUOTA_BYTES" '{email: $email, domain: $domain, password: $password, quota_bytes: $quota}')
        api_call POST "mailboxes" "$DATA"
        ;;
    "list-mailboxes")
        if [ -z "${2:-}" ]; then
            echo "ERROR: Domain name required"
            echo "Usage: $0 list-mailboxes <domain>"
            exit 1
        fi
        validate_domain "$2" || exit 1
        ENCODED_DOMAIN=$(printf %s "$2" | jq -sRr @uri)
        api_call GET "mailboxes?domain=$ENCODED_DOMAIN" | jq -r '.mailboxes[] | "\(.email) - \(.quota_bytes / 1048576)MB"'
        ;;
    "stats")
        api_call GET "stats" | jq .
        ;;
    *)
        echo "Usage: $0 {add-domain|add-mailbox|list-mailboxes|stats} [args]"
        exit 1
        ;;
esac