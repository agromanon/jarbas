---
name: weather-forecast
description: Fetches weather forecast for São Paulo Zona Oeste and sends it to Telegram
---

# Weather Forecast

Get daily weather forecasts for São Paulo Zona Oeste with hourly predictions for the daytime hours (8am-6pm).

## Usage

```bash
skills/weather-forecast/forecast.sh
```

Fetches the weather forecast from Open-Meteo API and sends a formatted message to Telegram.

## Output Format

```
🌤️ Previsão do Tempo - São Paulo Zona Oeste
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 Quinta-feira, 20/03/2026

☀️ 08h00 - 22°C ☁️ Chuva: 0% 💧 0.0mm
🌤️ 09h00 - 23°C ⛅ Chuva: 10% 💧 0.1mm
...
```

## Features

- **Location**: São Paulo Zona Oeste (lat: -23.55, lon: -46.70)
- **Time range**: Hourly forecast from 8:00 AM to 6:00 PM
- **Data points**:
  - Temperature (°C)
  - Rain probability (%)
  - Rain volume (mm)
- **Language**: Portuguese (pt-BR)
- **Delivery**: Telegram notification

## How It Works

1. Fetches weather data from Open-Meteo API (free, no API key required)
2. Extracts hourly data for the current day
3. Filters for daytime hours (8am-6pm)
4. Formats a friendly message with emojis
5. Sends to Telegram using `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` environment variables

## Error Handling

The script includes error handling for:
- Network failures (curl errors)
- Missing environment variables (TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID)
- Invalid API responses
- Missing weather data

## Requirements

- `curl` - For fetching data from Open-Meteo API and sending Telegram messages
- `jq` - For JSON parsing (fallback included for basic extraction)
- Environment variables:
  - `TELEGRAM_BOT_TOKEN` - Telegram bot token
  - `TELEGRAM_CHAT_ID` - Default chat ID for notifications

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `TELEGRAM_BOT_TOKEN` | Telegram bot token from @BotFather | Yes |
| `TELEGRAM_CHAT_ID` | Target chat ID for notifications | Yes |

## Example Cron Jobs

Add to `config/CRONS.json`:

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

## Integration

This skill is designed to work with:
- **Cron jobs**: Schedule automated weather updates
- **Manual execution**: Run anytime for current forecast
- **Telegram**: Delivers forecasts directly to your chat

## When to Use

- Daily weather briefings (morning and lunch)
- Planning outdoor activities
- Commute preparation
- Event planning
