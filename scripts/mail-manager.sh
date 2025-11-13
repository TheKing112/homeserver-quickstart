#!/bin/bash
set -euo pipefail

# Load environment variables
if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found"
    echo "Please run this script from the homeserver-quickstart directory"
    exit 1
fi

# Source .env file
set -a
source .env
set +a

# Validate required environment variables
if [ -z "${MAIL_API_TOKEN:-}" ]; then
    echo "ERROR: MAIL_API_TOKEN not set in .env file"
    echo "Please generate secrets first: ./scripts/00-generate-secrets.sh"
    exit 1
fi

API_URL="${MAIL_API_URL:-http://localhost:5000/api}"
API_TOKEN="${MAIL_API_TOKEN}"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    if [ -z "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            "$API_URL/$endpoint"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$API_URL/$endpoint"
    fi
}

case "$1" in
    "add-domain")
        echo "Adding domain: $2"
        DATA=$(jq -n --arg domain "$2" '{domain: $domain}')
        api_call POST "domains" "$DATA"
        ;;
    "add-mailbox")
        QUOTA_BYTES=$((${5:-1000} * 1048576))
        echo "Creating mailbox: $2@$3"
        DATA=$(jq -n --arg email "$2" --arg domain "$3" --arg password "$4" --argjson quota "$QUOTA_BYTES" '{email: $email, domain: $domain, password: $password, quota_bytes: $quota}')
        api_call POST "mailboxes" "$DATA"
        ;;
    "list-mailboxes")
        api_call GET "mailboxes?domain=$2" | jq -r '.mailboxes[] | "\(.email) - \(.quota_bytes / 1048576)MB"'
        ;;
    "stats")
        api_call GET "stats" | jq .
        ;;
    *)
        echo "Usage: $0 {add-domain|add-mailbox|list-mailboxes|stats} [args]"
        ;;
esac