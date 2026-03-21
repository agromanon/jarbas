/**
 * Telegram Webhook Handler with Weather Support
 *
 * This API route handles Telegram updates and:
 * 1. Forwards weather commands (/tempo, previsão) to the weather handler
 * 2. Forwards weather-bot updates to the dedicated weather-bot handler
 * 3. Forwards all updates to the original thepopebot Telegram webhook handler
 *
 * To use this as your Telegram webhook:
 * 1. Set the webhook URL to: https://your-domain.com/api/telegram/weather
 * 2. This will handle both weather commands and thepopebot features
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
 * Forward update to the weather handler
 */
async function forwardToWeatherHandler(update) {
  try {
    const updateJson = JSON.stringify(update).replace(/'/g, "'\\''");

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
 * Forward update to the weather-bot handler (dedicated bot)
 */
async function forwardToWeatherBotHandler(update) {
  try {
    const updateJson = JSON.stringify(update).replace(/'/g, "'\\''");

    const { stdout, stderr } = await execAsync(
      `node /job/triggers/weather-bot.js '${updateJson}'`,
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

export async function POST(request) {
  try {
    // Parse the Telegram update
    const update = await request.json();

    // Log the update for debugging
    console.log('Telegram update received:', JSON.stringify(update, null, 2));

    // Check if it contains a message or callback query
    const hasMessage = update.message && update.message.text;
    const hasCallbackQuery = update.callback_query;

    // Check if it's from the dedicated weather-bot (WEATHER_BOT_TOKEN is set)
    const isWeatherBot = process.env.WEATHER_BOT_TOKEN && hasMessage;
    const weatherBotCommands = ['/start', '/menu', '/location', '/help', '/allow', '/disallow', '/listusers'];

    let handled = false;

    // Handle weather-bot updates
    if (isWeatherBot) {
      if (hasCallbackQuery) {
        // Callback queries are always forwarded to weather-bot
        await forwardToWeatherBotHandler(update);
        handled = true;
      } else if (hasMessage) {
        const text = update.message.text.trim().toLowerCase();
        // Check if it's a weather-bot command
        const isWeatherBotCommand = weatherBotCommands.some(cmd => text === cmd);
        if (isWeatherBotCommand) {
          await forwardToWeatherBotHandler(update);
          handled = true;
        }
      }
    }

    // Handle weather commands from main bot
    if (!handled) {
      let isWeatherCommand = false;
      if (hasMessage) {
        const text = update.message.text.trim().toLowerCase();
        isWeatherCommand = text === '/tempo' || text === 'previsão';
      }

      // Handle weather commands and callbacks
      if (isWeatherCommand || hasCallbackQuery) {
        await forwardToWeatherHandler(update);
        handled = true;
      }
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
    message: 'Telegram Webhook Handler with Weather Support',
    features: [
      'Weather commands: /tempo, previsão',
      'Inline keyboard with forecast options',
      'Weather-bot integration: /start, /menu, /location, /help',
      'Integration with thepopebot chat features'
    ],
    webhook: {
      url: `${process.env.APP_URL || 'http://localhost:3000'}/api/telegram/weather`,
      method: 'POST'
    }
  });
}
