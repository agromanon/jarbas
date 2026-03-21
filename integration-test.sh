#!/bin/bash
# Integration test for weather forecast feature

echo "======================================"
echo "Weather Forecast Integration Test"
echo "======================================"
echo ""

# Test 1: Verify forecast script exists and is executable
echo "Test 1: Checking forecast script..."
if [ -x "/job/skills/weather-forecast/forecast.sh" ]; then
    echo "✓ Forecast script exists and is executable"
else
    echo "✗ Forecast script not found or not executable"
    exit 1
fi
echo ""

# Test 2: Test all forecast types
echo "Test 2: Testing forecast types..."
for type in today tomorrow 3days 7days; do
    output=$(/job/skills/weather-forecast/forecast.sh $type true 2>&1)
    if echo "$output" | grep -q '"message"'; then
        echo "✓ Forecast type '$type' works"
    else
        echo "✗ Forecast type '$type' failed"
        echo "Output: $output"
        exit 1
    fi
done
echo ""

# Test 3: Verify time filtering
echo "Test 3: Testing time filtering..."
current_hour=$(TZ='America/Sao_Paulo' date '+%H')
output=$(/job/skills/weather-forecast/forecast.sh today true 2>&1)
if echo "$output" | grep -q "${current_hour}h00"; then
    echo "✓ Time filtering works (includes current hour)"
else
    echo "⚠ Time filtering may not be working correctly"
fi
echo ""

# Test 4: Verify Telegram handler exists
echo "Test 4: Checking Telegram handler..."
if [ -x "/job/triggers/handle-telegram-weather.js" ]; then
    echo "✓ Telegram handler exists and is executable"
else
    echo "✗ Telegram handler not found or not executable"
    exit 1
fi
echo ""

# Test 5: Verify webhook route exists
echo "Test 5: Checking webhook route..."
if [ -f "/job/app/api/telegram/weather/route.js" ]; then
    echo "✓ Webhook route exists"
else
    echo "✗ Webhook route not found"
    exit 1
fi
echo ""

# Test 6: Verify trigger configuration
echo "Test 6: Checking trigger configuration..."
if cat /job/config/TRIGGERS.json | jq -e '.[] | select(.name == "telegram-weather")' > /dev/null; then
    echo "✓ Telegram weather trigger configured"
else
    echo "✗ Telegram weather trigger not configured"
    exit 1
fi
echo ""

# Test 7: Verify cron jobs
echo "Test 7: Checking cron jobs..."
if cat /job/config/CRONS.json | jq -e '.[] | select(.name == "weather-morning" and .enabled == true)' > /dev/null; then
    echo "✓ Weather morning cron job enabled"
else
    echo "✗ Weather morning cron job not enabled"
    exit 1
fi
if cat /job/config/CRONS.json | jq -e '.[] | select(.name == "weather-lunch" and .enabled == true)' > /dev/null; then
    echo "✓ Weather lunch cron job enabled"
else
    echo "✗ Weather lunch cron job not enabled"
    exit 1
fi
echo ""

# Test 8: Verify setup script
echo "Test 8: Checking setup script..."
if [ -x "/job/setup-weather-webhook.sh" ]; then
    echo "✓ Setup script exists and is executable"
else
    echo "✗ Setup script not found or not executable"
    exit 1
fi
echo ""

# Test 9: Verify documentation
echo "Test 9: Checking documentation..."
if [ -f "/job/docs/WEATHER_SETUP.md" ] && [ -f "/job/docs/WEATHER_QUICK_REFERENCE.md" ]; then
    echo "✓ Documentation exists"
else
    echo "✗ Documentation not found"
    exit 1
fi
echo ""

# Test 10: Verify package.json script
echo "Test 10: Checking package.json..."
if cat /job/package.json | jq -e '.scripts["setup-weather"]' > /dev/null; then
    echo "✓ Package.json setup-weather script exists"
else
    echo "✗ Package.json setup-weather script not found"
    exit 1
fi
echo ""

echo "======================================"
echo "✅ All integration tests passed!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Set environment variables (TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID, APP_URL)"
echo "2. Run: npm run setup-weather"
echo "3. Test in Telegram by sending: /tempo"
echo ""
