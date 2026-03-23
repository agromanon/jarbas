#!/bin/bash
# Setup script for Weather Bot Telegram Webhook
# This script configures your weather bot webhook and initializes data files

# Check if WEATHER_BOT_TOKEN is set
if [ -z "$WEATHER_BOT_TOKEN" ]; then
    echo "ERROR: WEATHER_BOT_TOKEN environment variable is not set"
    echo "Please set it in your .env file"
    exit 1
fi

# Check if APP_URL is set
if [ -z "$APP_URL" ]; then
    echo "ERROR: APP_URL environment variable is not set"
    echo "Please set it in your .env file"
    exit 1
fi

# Build the webhook URL (using /api/telegram/weather which handles both bots)
WEBHOOK_URL="${APP_URL}/api/telegram/weather"

echo "=========================================="
echo "Weather Bot - Telegram Setup"
echo "=========================================="
echo ""
echo "Bot Token: ${WEATHER_BOT_TOKEN:0:10}..."
echo "Webhook URL: ${WEBHOOK_URL}"
echo ""

# Initialize data files
echo "Step 1: Initializing data files..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/skills/weather-bot/init-data.sh" ]; then
    bash "${SCRIPT_DIR}/skills/weather-bot/init-data.sh"
else
    echo "⚠️ init-data.sh not found, skipping data initialization"
fi
echo ""

# Set the webhook
echo "Step 2: Configuring Telegram webhook..."
RESPONSE=$(curl -s -X POST \
    "https://api.telegram.org/bot${WEATHER_BOT_TOKEN}/setWebhook" \
    -H "Content-Type: application/json" \
    -d "{\"url\":\"${WEBHOOK_URL}\", \"allowed_updates\":[\"message\",\"callback_query\"]}")

# Check response
if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "✓ Telegram webhook configured successfully!"
    echo ""
    echo "=========================================="
    echo "Weather Bot Commands"
    echo "=========================================="
    echo ""
    echo "User Commands:"
    echo "  /start  - Show welcome message"
    echo "  /menu   - Show weather forecast menu"
    echo "  /location - Change your location"
    echo "  /help   - Show help"
    echo ""
    echo "Admin Commands (admin only):"
    echo "  /allow <chat_id>    - Authorize user"
    echo "  /disallow <chat_id> - Remove user authorization"
    echo "  /listusers         - List authorized users"
    echo ""
    echo "=========================================="
    echo "Setup complete!"
    echo "=========================================="
else
    echo "ERROR: Failed to set Telegram webhook"
    echo "Response: $RESPONSE"
    exit 1
fi
