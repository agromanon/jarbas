/**
 * Telegram Webhook Handler with Weather and Weather-Bot Support
 *
 * This API route handles Telegram updates and:
 * 1. Forwards weather commands (/tempo, previsão) to the weather handler
 * 2. Forwards weather-bot commands (/start, /menu, /location, etc.) to the weather-bot handler
 * 3. Forwards all updates to the original thepopebot Telegram webhook handler
 *
 * To use this as your Telegram webhook:
 * 1. Set the webhook URL to: https://your-domain.com/api/telegram/weather
 * 2. This will handle weather commands, weather-bot features, and thepopebot features
 *
 * Usage:
 *   POST /api/telegram/weather
 *
 * Expected body: Telegram Update object (JSON)
 */

import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

/**
 * Forward update to the original thepopebot Telegram webhook
 */
async function forwardToThpopebotHandler(update) {
  try {
    // Import the thepopebot telegram handler
    const telegramModule = await import('thepopebot/api');

    // The thepopebot package exports handlers, but we need to call the telegram webhook
    // This is a bit tricky since we can't directly import the internal handler
    // Instead, we'll make a local fetch request to the internal endpoint

    const baseUrl = process.env.APP_URL || 'http://localhost:3000';
    const response = await fetch(`${baseUrl}/api/telegram/webhook`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(update),
    });

    if (!response.ok) {
      console.error('Failed to forward to thepopebot handler:', response.status, response.statusText);
    }

    return response.ok;
  } catch (error) {
    console.error('Error forwarding to thepopebot handler:', error.message);
    return false;
  }
}

/**
 * Forward update to the weather handler (original)
 */
async function forwardToWeatherHandler(update) {
  try {
    // Escape single quotes for shell: ' becomes '"'"'
    const updateJson = JSON.stringify(update).replace(/'/g, "'\"'\"'");

    const { stdout, stderr } = await execAsync(
      `node /job/triggers/handle-telegram-weather.js '${updateJson}'`,
      {
        env: {
          ...process.env,
          TELEGRAM_BOT_TOKEN: process.env.TELEGRAM_BOT_TOKEN,
          TELEGRAM_CHAT_ID: process.env.TELEGRAM_CHAT_ID
        },
        timeout: 30000 // 30 second timeout
      }
    );

    console.log('Weather handler output:', stdout);
    if (stderr) {
      console.error('Weather handler stderr:', stderr);
    }
    return true;
  } catch (error) {
    console.error('Error running weather handler:', error.message);
    // Don't fail - the handler might have already responded
    return false;
  }
}

/**
 * Forward update to the weather-bot handler (advanced)
 */
async function forwardToWeatherBotHandler(update) {
  try {
    // Escape single quotes for shell: ' becomes '"'"'
    const updateJson = JSON.stringify(update).replace(/'/g, "'\"'\"'");

    const { stdout, stderr } = await execAsync(
      `node /app/triggers/weather-bot.js '${updateJson}'`,
      {
        env: {
          ...process.env,
          WEATHER_BOT_TOKEN: process.env.WEATHER_BOT_TOKEN,
          WEATHER_BOT_ADMIN_ID: process.env.WEATHER_BOT_ADMIN_ID
        },
        timeout: 30000 // 30 second timeout
      }
    );

    console.log('Weather-bot handler output:', stdout);
    if (stderr) {
      console.error('Weather-bot handler stderr:', stderr);
    }
    return true;
  } catch (error) {
    console.error('Error running weather-bot handler:', error.message);
    // Don't fail - the handler might have already responded
    return false;
  }
}

/**
 * Detect if this is a weather-bot command
 * Weather-bot commands: /start, /menu, /location, /allow, /disallow, /listusers, /help
 * Also handles all callback queries (weather-bot uses extensive inline keyboards)
 */
function isWeatherBotCommand(update) {
  const hasMessage = update.message && update.message.text;
  const hasCallbackQuery = update.callback_query;
  const hasLocation = update.message && update.message.location;

  // Callback queries are used by weather-bot
  if (hasCallbackQuery) {
    return true;
  }

  // Location sharing is used by weather-bot
  if (hasLocation) {
    return true;
  }

  // Check text commands
  if (hasMessage) {
    const text = update.message.text.trim().toLowerCase();
    const weatherBotCommands = ['/start', '/menu', '/location', '/allow', '/disallow', '/listusers', '/help', 'menu', 'localização', 'ajuda', 'listar'];
    return weatherBotCommands.some(cmd => text === cmd || text.startsWith(cmd + ' ')) || text.startsWith('city:') || text.startsWith('cidade:');
  }

  return false;
}

/**
 * Detect if this is a weather (original) command
 * Weather commands: /tempo, previsão
 */
function isWeatherCommand(update) {
  const hasMessage = update.message && update.message.text;
  const hasCallbackQuery = update.callback_query;

  // Callback queries starting with "weather_" are from the original weather handler
  if (hasCallbackQuery && update.callback_query.data && update.callback_query.data.startsWith('weather_')) {
    return true;
  }

  // Check text commands
  if (hasMessage) {
    const text = update.message.text.trim().toLowerCase();
    return text === '/tempo' || text === 'previsão';
  }

  return false;
}

export async function POST(request) {
  try {
    // Parse the Telegram update
    const update = await request.json();

    // Log the update for debugging
    console.log('Telegram update received:', JSON.stringify(update, null, 2));

    // Check which handler(s) should process this update
    const isWeatherBot = isWeatherBotCommand(update);
    const isWeather = isWeatherCommand(update);

    // Handle weather-bot commands first (more specific)
    if (isWeatherBot) {
      await forwardToWeatherBotHandler(update);
    }

    // Handle original weather commands
    if (isWeather) {
      await forwardToWeatherHandler(update);
    }

    // Always forward to thepopebot handler (for chat functionality, etc.)
    await forwardToThpopebotHandler(update);

    // Always return 200 OK to acknowledge the update
    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error('Error in Telegram webhook handler:', error);
    // Still return 200 to avoid Telegram retries
    return NextResponse.json({ ok: true, error: error.message });
  }
}

// Handle GET requests (for testing and webhook verification)
export async function GET() {
  return NextResponse.json({
    message: 'Telegram Webhook Handler with Weather and Weather-Bot Support',
    features: [
      'Weather commands: /tempo, previsão',
      'Weather-bot commands: /start, /menu, /location, /help',
      'Admin commands: /allow, /disallow, /listusers',
      'Location sharing via GPS/IP/Manual',
      'Inline keyboard with forecast options',
      'Integration with thepopebot chat features'
    ],
    webhook: {
      url: `${process.env.APP_URL || 'http://localhost:3000'}/api/telegram/weather`,
      method: 'POST'
    }
  });
}
