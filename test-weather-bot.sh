#!/bin/bash
# Test script for Weather Bot
# Tests the main components of the weather bot

echo "=========================================="
echo "Weather Bot - Test Script"
echo "=========================================="
echo ""

# Test 1: Check if skill files exist
echo "[1] Checking skill files..."
if [ -f "/job/skills/weather-bot/SKILL.md" ]; then
    echo "  ✓ SKILL.md exists"
else
    echo "  ✗ SKILL.md not found"
fi

if [ -f "/job/skills/weather-bot/weather.sh" ]; then
    echo "  ✓ weather.sh exists"
else
    echo "  ✗ weather.sh not found"
fi

if [ -f "/job/skills/weather-bot/send-daily.sh" ]; then
    echo "  ✓ send-daily.sh exists"
else
    echo "  ✗ send-daily.sh not found"
fi

if [ -x "/job/skills/weather-bot/weather.sh" ]; then
    echo "  ✓ weather.sh is executable"
else
    echo "  ✗ weather.sh is not executable"
fi

if [ -x "/job/skills/weather-bot/send-daily.sh" ]; then
    echo "  ✓ send-daily.sh is executable"
else
    echo "  ✗ send-daily.sh is not executable"
fi

echo ""

# Test 2: Check if trigger exists
echo "[2] Checking trigger file..."
if [ -f "/job/triggers/weather-bot.js" ]; then
    echo "  ✓ weather-bot.js exists"
else
    echo "  ✗ weather-bot.js not found"
fi

if [ -x "/job/triggers/weather-bot.js" ]; then
    echo "  ✓ weather-bot.js is executable"
else
    echo "  ✗ weather-bot.js is not executable"
fi

echo ""

# Test 3: Check if data files exist
echo "[3] Checking data files..."
if [ -f "/job/data/allowed-users.json" ]; then
    echo "  ✓ allowed-users.json exists"
else
    echo "  ✗ allowed-users.json not found"
fi

if [ -f "/job/data/user-locations.json" ]; then
    echo "  ✓ user-locations.json exists"
else
    echo "  ✗ user-locations.json not found"
fi

echo ""

# Test 4: Check if skill is activated
echo "[4] Checking if skill is activated..."
if [ -L "/job/skills/active/weather-bot" ]; then
    echo "  ✓ weather-bot skill is activated"
else
    echo "  ✗ weather-bot skill is not activated"
fi

echo ""

# Test 5: Check configuration files
echo "[5] Checking configuration files..."
if grep -q '"weather-bot"' "/job/config/TRIGGERS.json"; then
    echo "  ✓ weather-bot trigger configured in TRIGGERS.json"
else
    echo "  ✗ weather-bot trigger not found in TRIGGERS.json"
fi

if grep -q '"weather-bot-morning"' "/job/config/CRONS.json"; then
    echo "  ✓ weather-bot-morning cron configured in CRONS.json"
else
    echo "  ✗ weather-bot-morning cron not found in CRONS.json"
fi

if grep -q '"weather-bot-lunch"' "/job/config/CRONS.json"; then
    echo "  ✓ weather-bot-lunch cron configured in CRONS.json"
else
    echo "  ✗ weather-bot-lunch cron not found in CRONS.json"
fi

echo ""

# Test 6: Test weather script (dry run)
echo "[6] Testing weather script (dry run)..."
if [ -x "/job/skills/weather-bot/weather.sh" ]; then
    output=$(/job/skills/weather-bot/weather.sh today -23.55 -46.70 "São Paulo Zona Oeste" 2>&1)
    if echo "$output" | grep -q '"message"'; then
        echo "  ✓ weather.sh returns valid JSON"
    else
        echo "  ✗ weather.sh did not return valid JSON"
        echo "    Output: $output"
    fi
else
    echo "  ✗ weather.sh is not executable"
fi

echo ""

# Test 7: Check environment variables (warn only)
echo "[7] Checking environment variables..."
if [ -n "$WEATHER_BOT_TOKEN" ]; then
    echo "  ✓ WEATHER_BOT_TOKEN is set"
else
    echo "  ⚠ WEATHER_BOT_TOKEN is not set (set in .env file)"
fi

if [ -n "$WEATHER_BOT_ADMIN_ID" ]; then
    echo "  ✓ WEATHER_BOT_ADMIN_ID is set"
else
    echo "  ⚠ WEATHER_BOT_ADMIN_ID is not set (set in .env file)"
fi

if [ -n "$APP_URL" ]; then
    echo "  ✓ APP_URL is set"
else
    echo "  ⚠ APP_URL is not set (set in .env file)"
fi

echo ""
echo "=========================================="
echo "Test Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Set environment variables in .env file:"
echo "   WEATHER_BOT_TOKEN=8748218290:AAH0ht_meMiVa2U4zSDVOtFrZkyvOt_85x0"
echo "   WEATHER_BOT_ADMIN_ID=5121600266"
echo ""
echo "2. Run webhook setup:"
echo "   ./setup-weather-bot-webhook.sh"
echo ""
echo "3. Test the bot on Telegram:"
echo "   Send /start to @Perninhasclimabot"
echo ""
