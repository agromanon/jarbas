# Weather Bot Skill

A dedicated Telegram bot for weather forecasts with user authorization and location management.

## Features

- **Interactive menu** with inline buttons for quick access to forecasts
- **Multiple forecast periods**: Today, Tomorrow, Next 3 days, Next 7 days
- **User authorization system**: Admin-controlled access to the bot
- **Location management**: Users can set their own location via GPS, IP geolocation, or manual entry
- **Scheduled forecasts**: Automatic weather updates sent at configurable times via CRONS.json
- **Timezone-aware**: Filters forecast hours based on America/Sao_Paulo timezone

## Bot Commands

### User Commands
- `/start` - Show welcome message and menu
- `/menu` - Show weather forecast menu
- `/location` - Change your location
- `/help` - Show help message

### Admin Commands
- `/allow <chat_id>` - Authorize a user to access the bot
- `/disallow <chat_id>` - Remove user authorization
- `/listusers` - List all authorized users

## Configuration

### Environment Variables
- `WEATHER_BOT_TOKEN` - Telegram bot token (required)
- `WEATHER_BOT_ADMIN_ID` - Telegram chat ID of the admin (required)

### Data Files (stored in `data/` directory)
- `allowed-users.json` - Authorization database with admin ID, authorized users, and pending requests
- `user-locations.json` - User location preferences (lat, lon, name)
- `user-preferences.json` - User notification preferences (hours to receive forecasts)
- `pending-input.json` - Temporary state for multi-step inputs (e.g., waiting for city name)

## Scripts

### weather.sh
Main weather forecast script. Fetches data from Open-Meteo API and outputs formatted JSON.

Usage:
```bash
skills/weather-bot/weather.sh <type> <lat> <lon> <location_name>
```

Parameters:
- `type`: today, tomorrow, 3days, or 7days
- `lat`: latitude (e.g., -23.55)
- `lon`: longitude (e.g., -46.70)
- `location_name`: human-readable location name

Output: JSON with `message` field containing formatted forecast

### send-scheduled.sh
Sends forecasts to users who have configured notifications for a specific hour. Used by cron jobs.

Usage:
```bash
skills/weather-bot/send-scheduled.sh <hour>
```

Parameters:
- `hour`: 6, 8, 10, 12, 14, 16, or 18

This script:
1. Reads authorized users from `data/allowed-users.json`
2. Checks each user's notification preferences from `data/user-preferences.json`
3. Gets location from `data/user-locations.json`
4. Sends forecast only to users who have that hour configured

### init-data.sh
Initializes data files with default values if they don't exist. Run this once during setup.

Usage:
```bash
skills/weather-bot/init-data.sh
```

## Scheduled Forecasts (Cron Jobs)

Add these entries to `config/CRONS.json` to enable automatic forecasts:

```json
{
  "name": "weather-06h",
  "schedule": "0 6 * * *",
  "type": "command",
  "command": "/app/skills/weather-bot/send-scheduled.sh 6",
  "enabled": true
}
```

Users configure their preferred hours via the bot menu ("⚙️ Configurar horários").

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

1. Activate skill (create symlink):
   ```bash
   ln -s ../weather-bot skills/active/weather-bot
   ```

2. Initialize data files:
   ```bash
   WEATHER_BOT_ADMIN_ID=your_telegram_id skills/weather-bot/init-data.sh
   ```

3. Configure environment variables in `.env`:
   ```
   WEATHER_BOT_TOKEN=your_bot_token
   WEATHER_BOT_ADMIN_ID=your_telegram_id
   ```

4. Set up Telegram webhook:
   ```bash
   curl -X POST "https://api.telegram.org/bot<WEATHER_BOT_TOKEN>/setWebhook" \
     -H "Content-Type: application/json" \
     -d '{"url": "<APP_URL>/api/telegram/weather"}'
   ```

5. Add cron jobs to `config/CRONS.json` for scheduled forecasts

## API Usage

The weather.sh script outputs JSON format:
```json
{
  "message": "Formatted weather forecast text"
}
```

This allows the Telegram handler to easily parse and send the forecast.
