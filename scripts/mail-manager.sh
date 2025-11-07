#!/bin/bash

API_URL="http://localhost:5000/api"
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
        api_call POST "domains" "{\"domain\": \"$2\"}"
        ;;
    "add-mailbox")
        QUOTA_BYTES=$((${5:-1000} * 1048576))
        echo "Creating mailbox: $2@$3"
        api_call POST "mailboxes" "{\"email\": \"$2\", \"domain\": \"$3\", \"password\": \"$4\", \"quota_bytes\": $QUOTA_BYTES}"
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