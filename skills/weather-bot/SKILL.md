# Weather Bot Skill

A dedicated Telegram bot for weather forecasts with user authorization and location management.

## Features

- **Interactive menu** with inline buttons for quick access to forecasts
- **Multiple forecast periods**: Today, Tomorrow, Next 3 days, Next 7 days
- **User authorization system**: Admin-controlled access to the bot
- **Location management**: Users can set their own location via GPS, IP geolocation, or manual entry
- **Scheduled forecasts**: Automatic weather updates sent at configurable times
- **Timezone-aware**: Filters forecast hours based on America/Sao_Paulo timezone

## Bot Commands

### User Commands
- `/start` - Show welcome message and menu
- `/menu` - Show weather forecast menu
- `/location` - Change your location

### Admin Commands
- `/allow <chat_id>` - Authorize a user to access the bot
- `/disallow <chat_id>` - Remove user authorization
- `/listusers` - List all authorized users
- `/help` - Show help message

## Configuration

### Environment Variables
- `WEATHER_BOT_TOKEN` - Telegram bot token (required)
- `WEATHER_BOT_ADMIN_ID` - Telegram chat ID of the admin (required)
- `WEATHER_BOT_WEBHOOK_SECRET` - Secret for webhook validation (optional)

### Data Files
- `data/allowed-users.json` - Authorization database
- `data/user-locations.json` - User location preferences

## Scripts

### weather.sh
Main weather forecast script with functions:
- `get_forecast_today()` - Today's forecast (hours >= current time)
- `get_forecast_tomorrow()` - Tomorrow's full forecast
- `get_forecast_3days()` - Next 3 days
- `get_forecast_7days()` - Next 7 days

Usage:
```bash
skills/weather-bot/weather.sh <type> <chat_id>
```

Parameters:
- `type`: today, tomorrow, 3days, or 7days
- `chat_id`: Telegram chat ID to send forecast to

### send-daily.sh
Script for scheduled forecasts. Sends today's forecast to all authorized users at their configured locations.

## Location Management

Users can set their location through three methods:

1. **GPS location** - Share location via Telegram
2. **IP geolocation** - Automatically detect via IP address
3. **Manual entry** - Type city name (uses Open-Meteo geocoding)

Default location (if not set):
- Name: São Paulo Zona Oeste
- Latitude: -23.55
- Longitude: -46.70

## Setup

1. Create symlink to activate skill:
   ```bash
   ln -s ../weather-bot skills/active/weather-bot
   ```

2. Configure webhook (automatically via setup script or manually):
   ```bash
   curl -X POST "https://api.telegram.org/bot<WEATHER_BOT_TOKEN>/setWebhook" \
     -H "Content-Type: application/json" \
     -d '{"url": "<APP_URL>/api/telegram/weather-bot"}'
   ```

3. Add cron jobs to CRONS.json for scheduled forecasts (optional)

## API Usage

The weather.sh script outputs JSON format when called:
```json
{
  "message": "Formatted weather forecast text"
}
```

This allows the Telegram handler to easily parse and send the forecast.
