#!/bin/bash
# Test script for weather bot
# This script tests the weather forecast script with correct argument order
# Usage: bash test-weather.sh

echo "=== Weather Bot Test Script ==="
echo ""

SCRIPT_PATH="/job/skills/weather-bot/weather.sh"
LAT="-23.55"
LON="-46.70"
LOCATION="São Paulo Zona Oeste"

# Test if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ ERROR: Script not found at $SCRIPT_PATH"
    exit 1
fi

echo "✅ Script found at $SCRIPT_PATH"
echo ""

# Test dependencies
echo "=== Checking Dependencies ==="
if command -v curl &> /dev/null; then
    echo "✅ curl is installed"
else
    echo "❌ ERROR: curl is not installed"
    exit 1
fi

if command -v jq &> /dev/null; then
    echo "✅ jq is installed"
else
    echo "⚠️  jq is not installed (will use grep/sed fallback)"
fi
echo ""

# Test API directly
echo "=== Testing Open-Meteo API ==="
echo "Calling API..."
API_RESPONSE=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&hourly=temperature_2m&forecast_days=2&timezone=America/Sao_Paulo")

if echo "$API_RESPONSE" | jq -e '.hourly' > /dev/null 2>&1; then
    echo "✅ API is responding correctly"
else
    echo "❌ ERROR: API response is invalid"
    echo "Response: $API_RESPONSE"
    exit 1
fi
echo ""

# Test script with different forecast types
echo "=== Testing Weather Script ==="

echo ""
echo "Test 1: Today's forecast"
echo "Command: bash $SCRIPT_PATH today $LAT $LON '$LOCATION'"
OUTPUT=$(bash "$SCRIPT_PATH" today "$LAT" "$LON" "$LOCATION" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    if echo "$OUTPUT" | jq -e '.message' > /dev/null 2>&1; then
        MESSAGE=$(echo "$OUTPUT" | jq -r '.message')
        echo "✅ SUCCESS - Script returned valid JSON"
        echo "Message length: ${#MESSAGE} characters"
        echo "Preview: ${MESSAGE:0:100}..."
    else
        echo "❌ ERROR - Script returned invalid JSON"
        echo "Output: $OUTPUT"
        exit 1
    fi
else
    echo "❌ ERROR - Script exited with code $EXIT_CODE"
    echo "Output: $OUTPUT"
    exit 1
fi

echo ""
echo "Test 2: Tomorrow's forecast"
echo "Command: bash $SCRIPT_PATH tomorrow $LAT $LON '$LOCATION'"
OUTPUT=$(bash "$SCRIPT_PATH" tomorrow "$LAT" "$LON" "$LOCATION" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    if echo "$OUTPUT" | jq -e '.message' > /dev/null 2>&1; then
        MESSAGE=$(echo "$OUTPUT" | jq -r '.message')
        echo "✅ SUCCESS - Script returned valid JSON"
        echo "Message length: ${#MESSAGE} characters"
    else
        echo "❌ ERROR - Script returned invalid JSON"
        exit 1
    fi
else
    echo "❌ ERROR - Script exited with code $EXIT_CODE"
    exit 1
fi

echo ""
echo "=== Test with WRONG argument order (should fail) ==="
echo "Command: bash $SCRIPT_PATH $LAT $LON today"
echo "This demonstrates the common mistake of putting coordinates first"
OUTPUT=$(bash "$SCRIPT_PATH" "$LAT" "$LON" today 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "✅ Expected failure - Script correctly rejected invalid arguments"
    echo "Exit code: $EXIT_CODE"
else
    if echo "$OUTPUT" | jq -e '.error' > /dev/null 2>&1; then
        echo "✅ Expected failure - Script returned error message"
        echo "Error: $(echo "$OUTPUT" | jq -r '.error')"
    else
        echo "⚠️  Unexpected - Script should have failed with wrong argument order"
    fi
fi

echo ""
echo "=== All Tests Completed ==="
echo ""
echo "✅ Weather bot script is working correctly!"
echo ""
echo "Correct usage:"
echo "  bash $SCRIPT_PATH <type> <lat> <lon> <location>"
echo ""
echo "Examples:"
echo "  bash $SCRIPT_PATH today $LAT $LON '$LOCATION'"
echo "  bash $SCRIPT_PATH tomorrow $LAT $LON '$LOCATION'"
echo "  bash $SCRIPT_PATH 3days $LAT $LON '$LOCATION'"
echo "  bash $SCRIPT_PATH 7days $LAT $LON '$LOCATION'"
echo ""
