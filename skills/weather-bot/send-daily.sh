#!/bin/bash
# Send Daily Weather Forecast
# Sends today's forecast to all authorized users at their configured locations
#
# Usage: send-daily.sh

set -e

# Configuration
DATA_DIR="/job/data"
ALLOWED_USERS_FILE="${DATA_DIR}/allowed-users.json"
USER_LOCATIONS_FILE="${DATA_DIR}/user-locations.json"
WEATHER_BOT_TOKEN="${WEATHER_BOT_TOKEN}"

# Check if bot token is set
if [ -z "$WEATHER_BOT_TOKEN" ]; then
    echo "ERROR: WEATHER_BOT_TOKEN environment variable is not set"
    exit 1
fi

# Check if required files exist
if [ ! -f "$ALLOWED_USERS_FILE" ]; then
    echo "ERROR: Allowed users file not found: $ALLOWED_USERS_FILE"
    exit 1
fi

if [ ! -f "$USER_LOCATIONS_FILE" ]; then
    echo "ERROR: User locations file not found: $USER_LOCATIONS_FILE"
    exit 1
fi

# Function to get list of authorized users
get_authorized_users() {
    if command -v jq &> /dev/null; then
        jq -r '.allowed_users[]' "$ALLOWED_USERS_FILE"
    else
        grep -o '"allowed_users":\[[^]]*\]' "$ALLOWED_USERS_FILE" | \
            sed 's/"allowed_users":\[//;s/\]//;s/,/\n/g;s/"//g'
    fi
}

# Function to get user location
get_user_location() {
    local user_id="$1"
    if command -v jq &> /dev/null; then
        jq -r ".\"${user_id}\" | \"\\(.lat) \\(.lon) \\(.name)\"" "$USER_LOCATIONS_FILE"
    else
        # Fallback to default location if jq not available
        echo "-23.55 -46.70 São Paulo Zona Oeste"
    fi
}

# Function to send message to Telegram
send_telegram_message() {
    local chat_id="$1"
    local message="$2"

    # Escape special characters for JSON
    local escaped_message=$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')

    local payload="{\"chat_id\":\"${chat_id}\",\"text\":\"${escaped_message}\",\"parse_mode\":\"Markdown\"}"

    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "https://api.telegram.org/bot${WEATHER_BOT_TOKEN}/sendMessage" 2>&1)

    # Check response
    if echo "$response" | grep -q '"ok":true'; then
        echo "✓ Message sent to ${chat_id}"
        return 0
    else
        echo "✗ Failed to send to ${chat_id}: ${response}"
        return 1
    fi
}

# Function to get weather forecast
get_weather_forecast() {
    local type="$1"
    local lat="$2"
    local lon="$3"
    local location_name="$4"

    local script_path="/job/skills/weather-bot/weather.sh"
    local output

    output=$("$script_path" "$type" "$lat" "$lon" "$location_name" 2>&1) || {
        echo "ERROR: Failed to get weather forecast"
        return 1
    }

    # Return the message field from JSON
    if command -v jq &> /dev/null; then
        echo "$output" | jq -r '.message' | sed 's/\\n/\n/g'
    else
        echo "$output" | grep -o '"message":"[^"]*"' | \
            sed 's/"message":"//;s/"$//;s/\\n/\n/g'
    fi
}

# Main script
echo "=========================================="
echo "Sending Daily Weather Forecasts"
echo "=========================================="
echo ""

# Get list of authorized users
authorized_users=$(get_authorized_users)

if [ -z "$authorized_users" ]; then
    echo "WARNING: No authorized users found"
    exit 0
fi

user_count=0
success_count=0
failure_count=0

# Iterate through authorized users
for user_id in $authorized_users; do
    user_count=$((user_count + 1))
    echo "[${user_count}] Processing user: ${user_id}"

    # Get user location
    location_data=$(get_user_location "$user_id")

    if [ -z "$location_data" ]; then
        echo "  ✗ No location found for user ${user_id}"
        failure_count=$((failure_count + 1))
        continue
    fi

    # Parse location data
    lat=$(echo "$location_data" | awk '{print $1}')
    lon=$(echo "$location_data" | awk '{print $2}')
    location_name=$(echo "$location_data" | cut -d' ' -f3-)

    echo "  📍 Location: ${location_name} (${lat}, ${lon})"

    # Get weather forecast
    forecast_message=$(get_weather_forecast "today" "$lat" "$lon" "$location_name")

    if [ -z "$forecast_message" ]; then
        echo "  ✗ Failed to get weather forecast"
        failure_count=$((failure_count + 1))
        continue
    fi

    # Add header to message
    final_message="🌅 *Previsão do Dia - ${location_name}*\n\n${forecast_message}"

    # Send to Telegram
    if send_telegram_message "$user_id" "$final_message"; then
        success_count=$((success_count + 1))
    else
        failure_count=$((failure_count + 1))
    fi

    echo ""
done

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Total users: ${user_count}"
echo "Successful: ${success_count}"
echo "Failed: ${failure_count}"
echo "=========================================="

if [ $failure_count -gt 0 ]; then
    exit 1
fi

exit 0
