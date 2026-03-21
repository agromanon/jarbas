# Weather Forecast - Quick Reference

## User Guide

### Getting Weather Forecasts

#### Option 1: Automatic Daily Updates
Weather forecasts are sent automatically to your Telegram at:
- **6:00 AM** - Morning forecast
- **12:00 PM** - Lunchtime forecast

#### Option 2: Interactive Menu
Send one of these commands to your Telegram bot:
- `/tempo`
- `previsão`

You'll see an inline keyboard with options:
- 🌅 Hoje (restante do dia)
- 🌅 Amanhã
- 📅 Próximos 3 dias
- 📆 Próximos 7 dias

Click any button to see the forecast!

### Forecast Details

Each forecast shows:
- ☀️ Weather icon (based on rain probability)
- Time (hour)
- Temperature (°C)
- Rain probability (%)
- Rain amount (mm)

### Time Filtering

- **Today**: Shows only hours from now until 6 PM
  - Example: If it's 11 AM, you'll see 11 AM, 12 PM, 1 PM, etc.
- **Other options**: Full day forecasts (8 AM - 6 PM)

## Developer Quick Reference

### Forecast Script Usage

```bash
# Get forecast as JSON
skills/weather-forecast/forecast.sh today true

# Get forecast and send to Telegram
skills/weather-forecast/forecast.sh today false
# or just
skills/weather-forecast/forecast.sh today

# Available types
skills/weather-forecast/forecast.sh today    # Today (from current hour)
skills/weather-forecast/forecast.sh tomorrow  # Tomorrow (full day)
skills/weather-forecast/forecast.sh 3days    # Next 3 days
skills/weather-forecast/forecast.sh 7days    # Next 7 days
```

### Telegram Commands

| Command | Description |
|---------|-------------|
| `/tempo` | Show weather menu |
| `previsão` | Show weather menu |

### Callback Data

| Callback | Action |
|----------|--------|
| `weather_today` | Send today's forecast |
| `weather_tomorrow` | Send tomorrow's forecast |
| `weather_3days` | Send 3-day forecast |
| `weather_7days` | Send 7-day forecast |

### Webhook Endpoint

```
POST https://your-domain.com/api/telegram/weather
```

### Setup Commands

```bash
# Set up Telegram webhook
npm run setup-weather

# Test all forecast types
node test-weather-handler.js

# Test specific forecast
skills/weather-forecast/forecast.sh today true
```

## Configuration Files

| File | Purpose |
|------|---------|
| `config/CRONS.json` | Automatic forecast schedules |
| `config/TRIGGERS.json` | Telegram weather trigger |
| `skills/weather-forecast/forecast.sh` | Main forecast script |
| `triggers/handle-telegram-weather.js` | Telegram handler |
| `app/api/telegram/weather/route.js` | Webhook endpoint |

## Common Issues

### Issue: Webhook not set up
**Solution:**
```bash
npm run setup-weather
```

### Issue: Commands not responding
**Check:**
1. Environment variables are set
2. Bot token is valid
3. Webhook URL is correct

### Issue: Wrong time in forecast
**Check:**
1. `TIMEZONE` in forecast.sh is correct
2. System time is correct

## Support

Full documentation: `/job/docs/WEATHER_SETUP.md`
Implementation details: `/job/docs/WEATHER_IMPLEMENTATION_SUMMARY.md`
