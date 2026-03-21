# Weather Forecast Feature Setup Guide

This guide explains how to set up and use the enhanced weather forecast feature with interactive Telegram commands.

## Overview

The weather forecast feature provides:
- **Automatic daily forecasts** at 6 AM and 12 PM (via cron jobs)
- **Interactive Telegram commands** with inline keyboard buttons
- **Multiple forecast options**: Today, Tomorrow, Next 3 days, Next 7 days
- **Smart time filtering**: Shows only future hours for "today" forecasts
- **Telegram inline keyboard**: No LLM tokens consumed for menu interactions

## Quick Setup

### 1. Configure Environment Variables

Make sure these variables are set in your `.env` file:

```bash
# Telegram bot configuration
TELEGRAM_BOT_TOKEN=your_bot_token_from_botfather
TELEGRAM_CHAT_ID=your_chat_id_for_notifications
TELEGRAM_WEBHOOK_SECRET=your_webhook_secret

# Public URL (required for webhooks)
APP_URL=https://your-domain.com
```

### 2. Set Up the Telegram Webhook

Run the setup script to configure the Telegram webhook:

```bash
npm run setup-weather
```

Or manually:

```bash
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
  -H "Content-Type: application/json" \
  -d "{
    \"url\": \"${APP_URL}/api/telegram/weather\",
    \"allowed_updates\": [\"message\", \"callback_query\"]
  }"
```

### 3. Test the Feature

Send `/tempo` or `previsão` to your Telegram bot. You should see an inline keyboard with options:
- 🌅 Hoje (restante do dia)
- 🌅 Amanhã
- 📅 Próximos 3 dias
- 📆 Próximos 7 dias

## Features

### 1. Automatic Daily Forecasts

The system sends weather forecasts automatically:
- **Morning**: 6:00 AM - Forecast for today (from current hour onwards)
- **Lunch**: 12:00 PM - Forecast for today (from current hour onwards)

These are configured in `config/CRONS.json`:

```json
{
  "name": "weather-morning",
  "schedule": "0 6 * * *",
  "type": "command",
  "command": "skills/weather-forecast/forecast.sh",
  "enabled": true
},
{
  "name": "weather-lunch",
  "schedule": "0 12 * * *",
  "type": "command",
  "command": "skills/weather-forecast/forecast.sh",
  "enabled": true
}
```

### 2. Interactive Telegram Commands

#### `/tempo` or `previsão`

Shows an inline keyboard with forecast options. When you click a button:
- The bot acknowledges the callback (stops loading animation)
- Fetches the weather forecast from Open-Meteo API
- Sends the formatted forecast as a new message

#### Forecast Types

| Command | Description | Time Range |
|---------|-------------|------------|
| `today` | Today's forecast | From current hour to 6 PM |
| `tomorrow` | Tomorrow's forecast | 8 AM to 6 PM |
| `3days` | Next 3 days | 8 AM to 6 PM each day |
| `7days` | Next 7 days | 8 AM to 6 PM each day |

### 3. Time Filtering

The system intelligently filters forecast hours:
- **Today**: Shows only hours >= current time (e.g., if it's 11:45 AM, shows from 11 AM onwards)
- **Multi-day forecasts**: Shows full day forecasts (8 AM - 6 PM)

This ensures you never see outdated weather information.

## File Structure

```
/job/
├── skills/weather-forecast/
│   ├── SKILL.md           # Skill documentation
│   └── forecast.sh        # Main forecast script (supports types: today, tomorrow, 3days, 7days)
├── triggers/
│   ├── handle-telegram-weather.js  # Telegram command and callback handler
│   └── send-telegram-notification.js  # Original job notification handler
├── config/
│   ├── CRONS.json         # Contains weather-morning and weather-lunch cron jobs
│   └── TRIGGERS.json      # Contains telegram-weather trigger
├── app/api/telegram/weather/
│   └── route.js           # Webhook handler that forwards to both thepopebot and weather handler
├── setup-weather-webhook.sh  # Setup script for Telegram webhook
├── test-weather-handler.js    # Test script for forecast functionality
└── package.json           # Contains setup-weather script command
```

## Testing

### Test Forecast Scripts

Run the test suite to verify all forecast types work:

```bash
node test-weather-handler.js
```

### Test Individual Forecast Types

```bash
# Today's forecast (with time filtering)
skills/weather-forecast/forecast.sh today true

# Tomorrow's forecast
skills/weather-forecast/forecast.sh tomorrow true

# Next 3 days
skills/weather-forecast/forecast.sh 3days true

# Next 7 days
skills/weather-forecast/forecast.sh 7days true
```

The `true` argument outputs JSON instead of sending to Telegram.

### Test Telegram Handler

```bash
# Simulate a /tempo command
echo '{"message":{"chat":{"id":"test"},"text":"/tempo"}}' | \
  TELEGRAM_BOT_TOKEN=your_token \
  TELEGRAM_CHAT_ID=your_chat_id \
  node triggers/handle-telegram-weather.js
```

## API Endpoints

### POST /api/telegram/weather

Main webhook endpoint that receives Telegram updates.

**Request Body**: Telegram Update object (JSON)

**Behavior**:
1. Forwards weather commands (`/tempo`, `previsão`) to the weather handler
2. Forwards all updates to the original thepopebot Telegram webhook
3. Returns 200 OK to acknowledge the update

### GET /api/telegram/weather

Endpoint for testing and webhook verification.

**Response**:
```json
{
  "message": "Telegram Webhook Handler with Weather Support",
  "features": [
    "Weather commands: /tempo, previsão",
    "Inline keyboard with forecast options",
    "Integration with thepopebot chat features"
  ],
  "webhook": {
    "url": "https://your-domain.com/api/telegram/weather",
    "method": "POST"
  }
}
```

## Troubleshooting

### Webhook Not Working

1. **Check webhook URL**:
   ```bash
   curl "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo"
   ```

2. **Verify APP_URL is correct** in `.env`

3. **Check server logs** for error messages

### Weather Commands Not Responding

1. **Check environment variables** are set:
   ```bash
   echo $TELEGRAM_BOT_TOKEN
   echo $TELEGRAM_CHAT_ID
   ```

2. **Test the handler manually**:
   ```bash
   node triggers/handle-telegram-weather.js '{"message":{"chat":{"id":"123"},"text":"/tempo"}}'
   ```

3. **Check the forecast script**:
   ```bash
   skills/weather-forecast/forecast.sh today true
   ```

### Cron Jobs Not Sending

1. **Check cron configuration**:
   ```bash
   cat config/CRONS.json | grep -A 5 weather
   ```

2. **Verify cron jobs are enabled**:
   ```bash
   # Check in the web UI at /crons
   # Or verify the "enabled": true field in CRONS.json
   ```

3. **Test manual execution**:
   ```bash
   skills/weather-forecast/forecast.sh
   ```

### Time Filtering Not Working

1. **Check timezone**:
   ```bash
   date '+%H'  # Current hour (UTC)
   TZ='America/Sao_Paulo' date '+%H'  # Current hour (São Paulo)
   ```

2. **Verify timezone in forecast script**:
   ```bash
   grep "TIMEZONE=" skills/weather-forecast/forecast.sh
   # Should be: TIMEZONE="America/Sao_Paulo"
   ```

## Customization

### Change Location

Edit `skills/weather-forecast/forecast.sh`:

```bash
LATITUDE="-23.55"
LONGITUDE="-46.70"
LOCATION_NAME="São Paulo Zona Oeste"
TIMEZONE="America/Sao_Paulo"
```

### Change Forecast Hours

Edit `skills/weather-forecast/forecast.sh`:

```bash
START_HOUR=8   # Start showing forecasts at 8 AM
END_HOUR=18    # Stop showing forecasts at 6 PM
```

### Change Cron Schedule

Edit `config/CRONS.json` and modify the `schedule` field:

```json
{
  "schedule": "0 6 * * *"  // Cron expression: 6 AM daily
}
```

### Add More Forecast Options

1. Add the option type in `triggers/handle-telegram-weather.js` (inline keyboard)
2. Add the forecast type mapping in the same file
3. Add support in `skills/weather-forecast/forecast.sh`

## Security Notes

- The `TELEGRAM_BOT_TOKEN` is stored in `.env` (gitignored)
- Never commit `.env` to git
- The webhook secret (`TELEGRAM_WEBHOOK_SECRET`) validates incoming webhooks
- All Telegram commands are processed server-side (no LLM tokens consumed for menu interactions)

## API Limits

- **Open-Meteo API**: Free, no API key required, no rate limits
- **Telegram Bot API**: Standard rate limits apply (30 messages/second)
- **No LLM usage**: Menu interactions use inline keyboards (callback queries), which are free

## Support

For issues or questions:
1. Check this documentation
2. Review the logs in the web UI at `/notifications`
3. Test the scripts manually using the commands in this guide
4. Check the thepopebot documentation at `/job/CLAUDE.md`
