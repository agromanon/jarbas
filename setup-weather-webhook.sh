#!/bin/bash
# Setup script for Telegram Weather Webhook
# This script configures your Telegram bot to use the weather-enhanced webhook

# Check if TELEGRAM_BOT_TOKEN is set
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    echo "ERROR: TELEGRAM_BOT_TOKEN environment variable is not set"
    echo "Please set it in your .env file"
    exit 1
fi

# Check if APP_URL is set
if [ -z "$APP_URL" ]; then
    echo "ERROR: APP_URL environment variable is not set"
    echo "Please set it in your .env file"
    exit 1
fi

# Build the webhook URL
WEBHOOK_URL="${APP_URL}/api/telegram/weather"

echo "Setting Telegram webhook to: ${WEBHOOK_URL}"
echo ""

# Set the webhook
RESPONSE=$(curl -s -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
    -H "Content-Type: application/json" \
    -d "{\"url\":\"${WEBHOOK_URL}\", \"allowed_updates\":[\"message\",\"callback_query\"]}")

# Check response
if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "✓ Telegram webhook configured successfully!"
    echo ""
    echo "You can now use the following commands in Telegram:"
    echo "  /tempo - Get weather forecast menu"
    echo "  previsão - Get weather forecast menu"
    echo ""
    echo "The webhook URL is: ${WEBHOOK_URL}"
else
    echo "ERROR: Failed to set Telegram webhook"
    echo "Response: $RESPONSE"
    exit 1
fi
