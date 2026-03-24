#!/bin/bash
#
# AI Opportunity Radar - Telegram Sender
# Envia relatório formatado via Telegram API
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[telegram] $1"
}

error() {
    echo "[telegram] ERROR: $1" >&2
}

# Check arguments
if [ -z "$1" ]; then
    error "Usage: telegram.sh <report-file>"
    exit 1
fi

REPORT_FILE="$1"

if [ ! -f "$REPORT_FILE" ]; then
    error "Report file not found: $REPORT_FILE"
    exit 1
fi

# Check environment variables - support both RADAR_* and global TELEGRAM_*
BOT_TOKEN="${RADAR_TELEGRAM_BOT_TOKEN:-${TELEGRAM_BOT_TOKEN:-}}"
CHAT_ID="${RADAR_TELEGRAM_CHAT_ID:-${TELEGRAM_CHAT_ID:-}}"

if [ -z "$BOT_TOKEN" ]; then
    error "BOT_TOKEN not set"
    error ""
    error "Configure one of these GitHub secrets:"
    error "  AGENT_LLM_RADAR_TELEGRAM_BOT_TOKEN=<your-bot-token>"
    error "  AGENT_LLM_TELEGRAM_BOT_TOKEN=<your-bot-token>"
    error ""
    error "Or export directly:"
    error "  export RADAR_TELEGRAM_BOT_TOKEN=<your-bot-token>"
    error "  export TELEGRAM_BOT_TOKEN=<your-bot-token>"
    exit 1
fi

if [ -z "$CHAT_ID" ]; then
    error "CHAT_ID not set"
    error ""
    error "Configure one of these GitHub secrets:"
    error "  AGENT_LLM_RADAR_TELEGRAM_CHAT_ID=<your-chat-id>"
    error "  AGENT_LLM_TELEGRAM_CHAT_ID=<your-chat-id>"
    error ""
    error "To find your chat ID:"
    error "  1. Start a conversation with your bot on Telegram"
    error "  2. Visit: https://api.telegram.org/bot<TOKEN>/getUpdates"
    error "  3. Look for 'chat\":{\"id\":<YOUR_CHAT_ID>'"
    error "  4. Or use @userinfobot on Telegram"
    exit 1
fi

# Export for use in this script
export RADAR_TELEGRAM_BOT_TOKEN="$BOT_TOKEN"
export RADAR_TELEGRAM_CHAT_ID="$CHAT_ID"

TELEGRAM_API="https://api.telegram.org/bot${RADAR_TELEGRAM_BOT_TOKEN}"
MAX_MESSAGE_LENGTH=4096

# Read report content
REPORT_CONTENT=$(cat "$REPORT_FILE")
REPORT_LENGTH=${#REPORT_CONTENT}

log "Report length: $REPORT_LENGTH characters"

# Function to send message
send_message() {
    local text="$1"
    
    # Escape special characters for JSON
    local escaped_text=$(echo "$text" | jq -Rs .)
    
    local response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        "${TELEGRAM_API}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "{
            \"chat_id\": \"${RADAR_TELEGRAM_CHAT_ID}\",
            \"text\": ${escaped_text},
            \"disable_web_page_preview\": true
        }")
    
    local http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" != "200" ]; then
        error "Failed to send message. HTTP $http_code"
        error "Response: $body"
        return 1
    fi
    
    log "Message sent successfully"
    return 0
}

# Split message if needed
split_and_send() {
    local content="$1"
    local length=${#content}
    
    if [ "$length" -le "$MAX_MESSAGE_LENGTH" ]; then
        # Send as single message
        send_message "$content"
        return $?
    fi
    
    log "Message too long ($length chars), splitting..."
    
    # Split by sections (double newlines)
    local current_message=""
    local message_num=1
    
    while IFS= read -r line; do
        # Check if adding this line would exceed limit
        local potential_length=$(( ${#current_message} + ${#line} + 1 ))
        
        if [ "$potential_length" -gt "$MAX_MESSAGE_LENGTH" ]; then
            # Send current message
            if [ -n "$current_message" ]; then
                log "Sending part $message_num..."
                send_message "$current_message" || return 1
                message_num=$((message_num + 1))
                sleep 1  # Rate limiting
            fi
            current_message="$line"
        else
            if [ -n "$current_message" ]; then
                current_message="${current_message}"$'\n'"${line}"
            else
                current_message="$line"
            fi
        fi
    done <<< "$content"
    
    # Send remaining content
    if [ -n "$current_message" ]; then
        log "Sending part $message_num..."
        send_message "$current_message" || return 1
    fi
    
    return 0
}

# Alternative: Split by specific markers for better formatting
split_by_sections() {
    local content="$1"
    
    # Try to find natural split points
    local header=""
    local body="$content"
    
    # Extract header (first few lines until first product)
    header=$(echo "$content" | grep -B 100 "🏆 TOP" | head -20)
    
    if [ ${#header} -gt 0 ]; then
        # Send header first
        log "Sending header..."
        send_message "$header" || return 1
        sleep 1
        
        # Remove header from content
        body=$(echo "$content" | sed '1,/^🏆 TOP/d')
        
        # Split remaining by product entries
        local current_product=""
        local count=0
        
        while IFS= read -r line; do
            # New product marker
            if echo "$line" | grep -qE '^[0-9]️⃣'; then
                if [ -n "$current_product" ] && [ ${#current_product} -gt 100 ]; then
                    count=$((count + 1))
                    log "Sending product $count..."
                    send_message "$current_product" || return 1
                    sleep 1
                fi
                current_product="$line"
            else
                if [ -n "$current_product" ]; then
                    current_product="${current_product}"$'\n'"${line}"
                fi
            fi
        done <<< "$body"
        
        # Send last product and footer
        if [ -n "$current_product" ]; then
            count=$((count + 1))
            log "Sending product $count and footer..."
            send_message "$current_product" || return 1
        fi
    else
        # Fallback to simple split
        split_and_send "$content"
    fi
    
    return 0
}

# Main execution
log "Sending report via Telegram..."
log "Bot token: ${RADAR_TELEGRAM_BOT_TOKEN:0:10}..."
log "Chat ID: $RADAR_TELEGRAM_CHAT_ID"

# Try section-based split first, fallback to simple split
if ! split_by_sections "$REPORT_CONTENT"; then
    log "Section split failed, trying simple split..."
    split_and_send "$REPORT_CONTENT" || {
        error "Failed to send report"
        exit 1
    }
fi

log "Report sent successfully!"

exit 0
