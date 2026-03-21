#!/usr/bin/env node
/**
 * Telegram Weather Command Handler
 *
 * This script handles Telegram commands for weather forecasts:
 * - "/tempo" or "previsão" - Shows inline keyboard with options
 * - Callback queries from inline buttons - Sends weather forecast
 *
 * Usage:
 *   node handle-telegram-weather.js <json-payload>
 *
 * JSON payload should be a Telegram Update object:
 * - message: for text commands
 * - callback_query: for button clicks
 */

const { spawn } = require('child_process');
const https = require('https');

// Telegram bot token
const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;

// Main handler function
async function handleTelegramWeather() {
  if (!TELEGRAM_BOT_TOKEN) {
    console.error('ERROR: TELEGRAM_BOT_TOKEN environment variable is not set');
    process.exit(1);
  }

  // Get payload from command line argument
  const payloadJson = process.argv[2];
  if (!payloadJson) {
    console.error('ERROR: No Telegram update payload provided');
    process.exit(1);
  }

  let update;
  try {
    update = JSON.parse(payloadJson);
  } catch (error) {
    console.error('ERROR: Failed to parse Telegram update JSON:', error.message);
    process.exit(1);
  }

  console.log('Processing Telegram update...');

  try {
    // Check if it's a callback query (button click)
    if (update.callback_query) {
      await handleCallbackQuery(update.callback_query);
    }
    // Check if it's a message with text command
    else if (update.message && update.message.text) {
      await handleCommand(update.message);
    }
    else {
      console.log('Update does not contain a command or callback query, ignoring');
    }
  } catch (error) {
    console.error('ERROR: Failed to handle update:', error.message);
    // Don't exit, just log the error
  }
}

/**
 * Handle text commands (/tempo or "previsão")
 */
async function handleCommand(message) {
  const text = message.text.trim().toLowerCase();
  const chatId = message.chat.id;
  const messageId = message.message_id;

  console.log(`Command received from ${chatId}: ${text}`);

  // Check if it's a weather command
  const isWeatherCommand = text === '/tempo' || text === 'previsão';

  if (!isWeatherCommand) {
    console.log('Not a weather command, ignoring');
    return;
  }

  // Send inline keyboard with options
  const replyMarkup = {
    inline_keyboard: [
      [
        { text: '🌅 Hoje (restante do dia)', callback_data: 'weather_today' },
        { text: '🌅 Amanhã', callback_data: 'weather_tomorrow' }
      ],
      [
        { text: '📅 Próximos 3 dias', callback_data: 'weather_3days' },
        { text: '📆 Próximos 7 dias', callback_data: 'weather_7days' }
      ]
    ]
  };

  const responseText = '🌤️ *Escolha o período da previsão:*\n\nSelecione uma opção abaixo para ver o clima para São Paulo Zona Oeste.';

  await sendTelegramMessage(chatId, responseText, {
    reply_markup: replyMarkup,
    parse_mode: 'Markdown'
  });

  console.log('✓ Weather menu sent to Telegram');
}

/**
 * Handle callback query (button click)
 */
async function handleCallbackQuery(callbackQuery) {
  const callbackId = callbackQuery.id;
  const data = callbackQuery.data;
  const chatId = callbackQuery.message.chat.id;
  const messageId = callbackQuery.message.message_id;

  console.log(`Callback query received: ${data} from ${chatId}`);

  // Acknowledge the callback query (stop the loading animation)
  await answerCallbackQuery(callbackId);

  // Map callback data to forecast type
  const forecastTypeMap = {
    'weather_today': 'today',
    'weather_tomorrow': 'tomorrow',
    'weather_3days': '3days',
    'weather_7days': '7days'
  };

  const forecastType = forecastTypeMap[data];
  if (!forecastType) {
    console.log('Unknown callback data:', data);
    return;
  }

  // Get weather forecast
  try {
    const forecastMessage = await getWeatherForecast(forecastType);

    // Send the forecast as a new message
    await sendTelegramMessage(chatId, forecastMessage, {
      parse_mode: 'Markdown'
    });

    console.log(`✓ Weather forecast sent (${forecastType})`);
  } catch (error) {
    console.error('ERROR: Failed to get weather forecast:', error.message);

    const errorMessage = '❌ *Erro ao obter previsão do tempo*\n\nTente novamente em alguns minutos.';

    await sendTelegramMessage(chatId, errorMessage, {
      parse_mode: 'Markdown'
    });
  }
}

/**
 * Acknowledge a callback query (stop loading animation)
 */
async function answerCallbackQuery(callbackId, text = null) {
  const postData = JSON.stringify({ callback_query_id: callbackId, text });

  await makeTelegramRequest('/answerCallbackQuery', postData);
}

/**
 * Send a message to Telegram
 */
async function sendTelegramMessage(chatId, text, options = {}) {
  const postData = JSON.stringify({
    chat_id: chatId,
    text: text,
    ...options
  });

  return await makeTelegramRequest('/sendMessage', postData);
}

/**
 * Make a request to the Telegram Bot API
 */
function makeTelegramRequest(method, postData) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.telegram.org',
      port: 443,
      path: `/bot${TELEGRAM_BOT_TOKEN}${method}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          const response = JSON.parse(data);
          if (response.ok) {
            resolve(response);
          } else {
            reject(new Error(`Telegram API error: ${response.description}`));
          }
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

/**
 * Get weather forecast by running the forecast.sh script
 */
function getWeatherForecast(type) {
  return new Promise((resolve, reject) => {
    const scriptPath = '/job/skills/weather-forecast/forecast.sh';
    const args = [type, 'true']; // type and output_json=true

    console.log(`Running forecast script: ${scriptPath} ${args.join(' ')}`);

    const child = spawn(scriptPath, args, {
      env: {
        ...process.env,
        TELEGRAM_BOT_TOKEN: process.env.TELEGRAM_BOT_TOKEN,
        TELEGRAM_CHAT_ID: process.env.TELEGRAM_CHAT_ID
      }
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    child.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    child.on('close', (code) => {
      if (code !== 0) {
        console.error('Forecast script error:', stderr);
        reject(new Error(`Forecast script exited with code ${code}: ${stderr}`));
        return;
      }

      try {
        // Parse the JSON output
        const result = JSON.parse(stdout.trim());
        resolve(result.message);
      } catch (error) {
        console.error('Failed to parse forecast JSON:', stdout);
        reject(new Error(`Failed to parse forecast JSON: ${error.message}`));
      }
    });

    child.on('error', (error) => {
      console.error('Failed to spawn forecast script:', error);
      reject(error);
    });
  });
}

// Run the handler
handleTelegramWeather().catch((error) => {
  console.error('ERROR: Unhandled error:', error);
  process.exit(1);
});
