# Weather Forecast Enhancement

Enhanced weather forecast skill with interactive Telegram commands, smart time filtering, and multiple forecast options.

## Overview

This enhancement adds interactive Telegram commands to the existing weather forecast feature, allowing users to quickly get weather forecasts for different time periods without using LLM tokens.

## Features

### ✅ Implemented

1. **Smart Time Filtering**
   - Shows only future hours for "today" forecasts
   - Example: If it's 11 AM, the forecast starts from 11 AM onwards
   - Applies to both cron jobs and manual commands

2. **Interactive Telegram Menu**
   - Command: `/tempo` or `previsão`
   - Inline keyboard with 4 options:
     - 🌅 Hoje (restante do dia)
     - 🌅 Amanhã
     - 📅 Próximos 3 dias
     - 📆 Próximos 7 dias
   - Instant response, no LLM tokens consumed

3. **Multiple Forecast Types**
   - Today: Current day (from current hour to 6 PM)
   - Tomorrow: Next day (8 AM to 6 PM)
   - 3 days: Next 3 days (8 AM to 6 PM each day)
   - 7 days: Next 7 days (8 AM to 6 PM each day)

4. **Unified Webhook**
   - Single endpoint handles both weather and thepopebot features
   - Maintains backward compatibility
   - No breaking changes

5. **Easy Setup**
   - Automated webhook configuration
   - Comprehensive documentation
   - Integration tests included

## Quick Start

### Prerequisites

- Telegram bot token from @BotFather
- Telegram chat ID
- APP_URL (your public URL)

### Setup

1. **Configure environment variables** in `.env`:
   ```bash
   TELEGRAM_BOT_TOKEN=your_bot_token
   TELEGRAM_CHAT_ID=your_chat_id
   APP_URL=https://your-domain.com
   ```

2. **Set up the webhook**:
   ```bash
   npm run setup-weather
   ```

3. **Test in Telegram**:
   - Send `/tempo` to your bot
   - Click any button to see the forecast

## Usage

### For Users

**Automatic Daily Forecasts:**
- 6:00 AM - Morning forecast
- 12:00 PM - Lunchtime forecast

**Interactive Menu:**
- Send `/tempo` or `previsão`
- Choose from the inline keyboard options

### For Developers

**Get forecast as JSON:**
```bash
skills/weather-forecast/forecast.sh today true
```

**Test all forecast types:**
```bash
node test-weather-handler.js
```

**Run integration tests:**
```bash
./integration-test.sh
```

## File Structure

```
/job/
├── skills/weather-forecast/
│   ├── forecast.sh          # Enhanced forecast script
│   └── SKILL.md             # Skill documentation
├── triggers/
│   └── handle-telegram-weather.js  # Telegram handler
├── config/
│   ├── CRONS.json           # Weather cron jobs
│   └── TRIGGERS.json        # Weather trigger
├── app/api/telegram/weather/
│   └── route.js             # Unified webhook endpoint
├── docs/
│   ├── WEATHER_SETUP.md              # Setup guide
│   ├── WEATHER_QUICK_REFERENCE.md    # Quick reference
│   └── WEATHER_IMPLEMENTATION_SUMMARY.md  # Implementation details
├── setup-weather-webhook.sh  # Webhook setup script
├── test-weather-handler.js   # Test suite
└── integration-test.sh        # Integration tests
```

## Testing

All tests pass successfully:

```bash
./integration-test.sh
```

Output:
```
======================================
Weather Forecast Integration Test
======================================

Test 1: ✓ Forecast script exists and is executable
Test 2: ✓ Forecast types work (today, tomorrow, 3days, 7days)
Test 3: ✓ Time filtering works
Test 4: ✓ Telegram handler exists
Test 5: ✓ Webhook route exists
Test 6: ✓ Trigger configuration correct
Test 7: ✓ Cron jobs enabled
Test 8: ✓ Setup script exists
Test 9: ✓ Documentation exists
Test 10: ✓ Package.json script exists

✅ All integration tests passed!
```

## Documentation

- **Setup Guide**: `/job/docs/WEATHER_SETUP.md` - Comprehensive setup and troubleshooting
- **Quick Reference**: `/job/docs/WEATHER_QUICK_REFERENCE.md` - User and developer quick reference
- **Implementation Summary**: `/job/docs/WEATHER_IMPLEMENTATION_SUMMARY.md` - Technical details and decisions

## Configuration

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
START_HOUR=8   # Start hour
END_HOUR=18    # End hour
```

### Change Cron Schedule

Edit `config/CRONS.json`:
```json
{
  "schedule": "0 6 * * *"  // Cron expression
}
```

## Benefits

### For Users
- ✅ Interactive menu (no need to remember commands)
- ✅ Multiple forecast options
- ✅ Instant response (inline keyboards)
- ✅ No LLM token cost for menu navigation
- ✅ Automatic daily updates

### For Developers
- ✅ Modular, maintainable code
- ✅ Comprehensive error handling
- ✅ Easy to extend and customize
- ✅ Well-documented
- ✅ Testable components

## Technical Details

- **API**: Open-Meteo (free, no API key required)
- **Telegram**: Inline keyboards (no LLM usage)
- **Time filtering**: Shell script (fast, lightweight)
- **Webhook**: Node.js (async, non-blocking)

## Security

- ✅ Secrets in `.env` (gitignored)
- ✅ Input validation
- ✅ No secrets in code
- ✅ Error messages don't leak data

## Compatibility

- ✅ Works with existing thepopebot features
- ✅ Backward compatible cron jobs
- ✅ No breaking changes
- ✅ Maintains all existing functionality

## Changelog

### Version 1.0.0 (2025-03-21)

**Added:**
- Multiple forecast types (today, tomorrow, 3days, 7days)
- Smart time filtering for today's forecasts
- Interactive Telegram menu with inline keyboards
- Callback query handling
- Unified webhook endpoint
- Automated webhook setup
- Comprehensive documentation
- Integration tests

**Modified:**
- `skills/weather-forecast/forecast.sh` - Enhanced with multiple types
- `config/TRIGGERS.json` - Added telegram-weather trigger
- `package.json` - Added setup-weather script

**Maintained:**
- All existing cron jobs (weather-morning, weather-lunch)
- All existing thepopebot features
- Full backward compatibility

## Support

For issues or questions:
1. Check `/job/docs/WEATHER_SETUP.md` for troubleshooting
2. Run `./integration-test.sh` to verify setup
3. Check `/notifications` in the web UI
4. Review the implementation documentation

## License

Same as the parent thepopebot project.
