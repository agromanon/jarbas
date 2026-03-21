/**
 * Weather Bot Telegram Webhook
 *
 * This API route handles Telegram updates for the dedicated weather bot (@Perninhasclimabot).
 *
 * To use this as your Telegram webhook:
 * curl -X POST "https://api.telegram.org/bot${WEATHER_BOT_TOKEN}/setWebhook" \
 *   -H "Content-Type: application/json" \
 *   -d '{"url": "${APP_URL}/api/telegram/webhook/weather-bot"}'
 *
 * Usage:
 *   POST /api/telegram/webhook/weather-bot
 *
 * Expected body: Telegram Update object (JSON)
 */

import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function POST(request) {
  try {
    // Parse the Telegram update
    const update = await request.json();

    // Log the update for debugging
    console.log('Weather bot Telegram update received:', JSON.stringify(update, null, 2));

    // Forward to the weather-bot handler
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

    if (stdout) {
      console.log('Weather bot handler output:', stdout);
    }
    if (stderr) {
      console.error('Weather bot handler stderr:', stderr);
    }

    // Always return 200 OK to acknowledge the update
    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error('Error in weather bot webhook handler:', error);
    // Still return 200 to avoid Telegram retries
    return NextResponse.json({ ok: true, error: error.message });
  }
}

// Handle GET requests (for testing and webhook verification)
export async function GET() {
  return NextResponse.json({
    message: 'Weather Bot Telegram Webhook',
    bot: '@Perninhasclimabot',
    features: [
      'User authorization system',
      'Location management (GPS, IP, manual)',
      'Interactive menu with inline buttons',
      'Multiple forecast options: Today, Tomorrow, 3 days, 7 days',
      'Admin commands: /allow, /disallow, /listusers'
    ],
    webhook: {
      url: `${process.env.APP_URL || 'http://localhost:3000'}/api/telegram/webhook/weather-bot`,
      method: 'POST'
    }
  });
}
