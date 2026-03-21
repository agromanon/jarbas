#!/usr/bin/env node
/**
 * Weather Bot - Telegram Handler
 *
 * Dedicated Telegram bot for weather forecasts with authorization and location management.
 *
 * Commands:
 * - /start, /menu - Show welcome message and forecast menu
 * - /location - Change user location
 * - /allow <chat_id> - Admin: Authorize user
 * - /disallow <chat_id> - Admin: Remove user authorization
 * - /listusers - Admin: List authorized users
 * - /help - Show help
 *
 * Features:
 * - User authorization system
 * - Location management (GPS, IP, manual)
 * - Interactive menu with inline buttons
 * - Multiple forecast periods
 */

const https = require('https');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

// Configuration
const DATA_DIR = path.join(__dirname, '../data');
const ALLOWED_USERS_FILE = path.join(DATA_DIR, 'allowed-users.json');
const USER_LOCATIONS_FILE = path.join(DATA_DIR, 'user-locations.json');

const WEATHER_BOT_TOKEN = process.env.WEATHER_BOT_TOKEN;
const WEATHER_BOT_ADMIN_ID = parseInt(process.env.WEATHER_BOT_ADMIN_ID || '0');

// Default location
const DEFAULT_LOCATION = {
  lat: -23.55,
  lon: -46.70,
  name: 'São Paulo Zona Oeste'
};

/**
 * Main handler function
 */
async function handleWeatherBot() {
  if (!WEATHER_BOT_TOKEN) {
    console.error('ERROR: WEATHER_BOT_TOKEN environment variable is not set');
    process.exit(1);
  }

  if (!WEATHER_BOT_ADMIN_ID) {
    console.error('ERROR: WEATHER_BOT_ADMIN_ID environment variable is not set');
    process.exit(1);
  }

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
    // Check if it's a message
    else if (update.message) {
      await handleMessage(update.message);
    }
    else {
      console.log('Update does not contain a message or callback query, ignoring');
    }
  } catch (error) {
    console.error('ERROR: Failed to handle update:', error.message);
  }
}

/**
 * Handle messages (text commands, location sharing)
 */
async function handleMessage(message) {
  const chatId = message.chat.id;
  const text = message.text ? message.text.trim() : '';
  const userId = message.from?.id || chatId;

  console.log(`Message received from ${chatId} (user: ${userId}): ${text || '<no text>'}`);

  // Check authorization for all commands except /start
  if (text && text !== '/start' && !isAuthorized(userId)) {
    await sendAuthorizationMessage(chatId, userId);
    return;
  }

  // Handle location sharing
  if (message.location) {
    await handleLocationSharing(chatId, message.location);
    return;
  }

  // Handle text commands
  if (!text) {
    return;
  }

  const command = text.toLowerCase();

  switch (command) {
    case '/start':
      await handleStart(chatId);
      break;
    case '/menu':
    case 'menu':
      await showForecastMenu(chatId);
      break;
    case '/location':
    case 'localização':
      await showLocationMenu(chatId);
      break;
    case '/help':
    case 'ajuda':
      await showHelp(chatId);
      break;
    default:
      if (command.startsWith('/allow ')) {
        await handleAllow(chatId, command);
      } else if (command.startsWith('/disallow ')) {
        await handleDisallow(chatId, command);
      } else if (command === '/listusers' || command === '/listar') {
        await handleListUsers(chatId);
      } else if (command.startsWith('city:') || command.startsWith('cidade:')) {
        await handleCityLocation(chatId, command);
      } else {
        // Unknown command
        await sendTelegramMessage(chatId, '❓ Comando não reconhecido.\n\nUse /help para ver a lista de comandos disponíveis.');
      }
  }
}

/**
 * Handle callback queries (button clicks)
 */
async function handleCallbackQuery(callbackQuery) {
  const callbackId = callbackQuery.id;
  const data = callbackQuery.data;
  const chatId = callbackQuery.message.chat.id;
  const userId = callbackQuery.from?.id || chatId;

  console.log(`Callback query received: ${data} from ${chatId} (user: ${userId})`);

  // Acknowledge the callback query
  await answerCallbackQuery(callbackId);

  // Check authorization for all callbacks except location-related
  if (!data.startsWith('location_') && !data.startsWith('loc_menu_') && !isAuthorized(userId)) {
    await sendAuthorizationMessage(chatId, userId);
    return;
  }

  // Handle different callback types
  if (data === 'menu') {
    await showForecastMenu(chatId);
  } else if (data === 'location_menu') {
    await showLocationMenu(chatId);
  } else if (data.startsWith('weather_')) {
    await handleWeatherForecast(chatId, data);
  } else if (data === 'location_gps') {
    await requestLocation(chatId);
  } else if (data === 'location_ip') {
    await handleIPLocation(chatId);
  } else if (data === 'location_manual') {
    await requestCityName(chatId);
  } else if (data.startsWith('city:')) {
    await handleCityLocation(chatId, data);
  } else if (data === 'help') {
    await showHelp(chatId);
  }
}

/**
 * Handle /start command
 */
async function handleStart(chatId) {
  const userId = chatId; // Assume chatId is userId for now

  const welcomeMessage = `🌤️ *Bem-vindo ao Perninhasclimabot!*

Sou seu assistente de previsão do tempo.

`;

  if (isAuthorized(userId)) {
    const location = getUserLocation(userId);
    welcomeMessage += `Você está autorizado a usar o bot.\n\nSua localização atual: ${location.name}\n\n`;
    welcomeMessage += `Use o botão abaixo para ver o menu de previsão:`;

    await sendTelegramMessage(chatId, welcomeMessage, {
      reply_markup: {
        inline_keyboard: [[
          { text: '📅 Ver Previsão', callback_data: 'menu' }
        ]]
      },
      parse_mode: 'Markdown'
    });
  } else {
    welcomeMessage += `Você ainda não está autorizado a usar este bot.\n\n`;
    welcomeMessage += `Por favor, entre em contato com o administrador para solicitar acesso.\n\n`;
    welcomeMessage += `Seu ID de usuário: \`${userId}\``;

    await sendTelegramMessage(chatId, welcomeMessage, {
      parse_mode: 'Markdown'
    });
  }
}

/**
 * Show forecast menu
 */
async function showForecastMenu(chatId) {
  const location = getUserLocation(chatId);

  const replyMarkup = {
    inline_keyboard: [
      [
        { text: '🌅 Hoje', callback_data: 'weather_today' },
        { text: '🌅 Amanhã', callback_data: 'weather_tomorrow' }
      ],
      [
        { text: '📅 Próximos 3 dias', callback_data: 'weather_3days' },
        { text: '📆 Próximos 7 dias', callback_data: 'weather_7days' }
      ],
      [
        { text: '📍 Alterar Localização', callback_data: 'location_menu' },
        { text: '❓ Ajuda', callback_data: 'help' }
      ]
    ]
  };

  const responseText = `🌤️ *Escolha o período da previsão:*\n\nLocalização atual: ${location.name}\n\nSelecione uma opção abaixo:`;

  await sendTelegramMessage(chatId, responseText, {
    reply_markup: replyMarkup,
    parse_mode: 'Markdown'
  });

  console.log('✓ Forecast menu sent to Telegram');
}

/**
 * Show location menu
 */
async function showLocationMenu(chatId) {
  const location = getUserLocation(chatId);

  const replyMarkup = {
    inline_keyboard: [
      [
        { text: '📍 Enviar Localização (GPS)', callback_data: 'location_gps' }
      ],
      [
        { text: '💻 Usar Localização por IP', callback_data: 'location_ip' }
      ],
      [
        { text: '✏️ Digitar Cidade', callback_data: 'location_manual' }
      ],
      [
        { text: '⬅️ Voltar', callback_data: 'menu' }
      ]
    ]
  };

  const responseText = `🗺️ *Alterar Localização*\n\nLocalização atual: ${location.name}\n\nEscolha como deseja definir sua localização:`;

  await sendTelegramMessage(chatId, responseText, {
    reply_markup: replyMarkup,
    parse_mode: 'Markdown'
  });

  console.log('✓ Location menu sent to Telegram');
}

/**
 * Handle weather forecast
 */
async function handleWeatherForecast(chatId, data) {
  const forecastTypeMap = {
    'weather_today': 'today',
    'weather_tomorrow': 'tomorrow',
    'weather_3days': '3days',
    'weather_7days': '7days'
  };

  const forecastType = forecastTypeMap[data];
  if (!forecastType) {
    console.log('Unknown forecast type:', data);
    return;
  }

  const location = getUserLocation(chatId);

  try {
    const forecastMessage = await getWeatherForecast(forecastType, location.lat, location.lon, location.name);

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
 * Request user's GPS location
 */
async function requestLocation(chatId) {
  const responseText = '📍 Por favor, compartilhe sua localização clicando no botão abaixo:';

  await sendTelegramMessage(chatId, responseText, {
    reply_markup: {
      keyboard: [[
        { text: '📍 Enviar Localização', request_location: true }
      ]],
      one_time_keyboard: true,
      resize_keyboard: true
    }
  });

  console.log('✓ Location request sent');
}

/**
 * Handle location sharing from user
 */
async function handleLocationSharing(chatId, location) {
  const lat = location.latitude;
  const lon = location.longitude;

  try {
    // Get location name via reverse geocoding
    const locationName = await getLocationName(lat, lon);

    // Save user location
    saveUserLocation(chatId, lat, lon, locationName);

    const responseText = `✅ *Localização atualizada!*\n\n📍 ${locationName}\n\nLat: ${lat.toFixed(4)}, Lon: ${lon.toFixed(4)}`;

    await sendTelegramMessage(chatId, responseText, {
      reply_markup: { remove_keyboard: true },
      parse_mode: 'Markdown'
    });

    console.log(`✓ Location saved for ${chatId}: ${locationName}`);
  } catch (error) {
    console.error('ERROR: Failed to process location:', error.message);
    await sendTelegramMessage(chatId, '❌ Erro ao processar localização. Tente novamente.');
  }
}

/**
 * Handle IP-based location
 */
async function handleIPLocation(chatId) {
  await sendTelegramMessage(chatId, '🔄 Detectando localização via IP... Aguarde...');

  try {
    const location = await getIPLocation();

    // Get location name via reverse geocoding
    const locationName = await getLocationName(location.lat, location.lon);

    // Save user location
    saveUserLocation(chatId, location.lat, location.lon, locationName);

    const responseText = `✅ *Localização detectada!*\n\n📍 ${locationName}\n\nLat: ${location.lat.toFixed(4)}, Lon: ${location.lon.toFixed(4)}`;

    await sendTelegramMessage(chatId, responseText, {
      parse_mode: 'Markdown'
    });

    console.log(`✓ IP-based location saved for ${chatId}: ${locationName}`);
  } catch (error) {
    console.error('ERROR: Failed to get IP location:', error.message);
    await sendTelegramMessage(chatId, '❌ Erro ao detectar localização via IP. Tente usar GPS ou digitar o nome da cidade.');
  }
}

/**
 * Request city name from user
 */
async function requestCityName(chatId) {
  const responseText = '✏️ Digite o nome da cidade:\n\nExemplo: São Paulo, Rio de Janeiro, Curitiba';

  await sendTelegramMessage(chatId, responseText, {
    reply_markup: {
      force_reply: true
    }
  });

  console.log('✓ City name request sent');
}

/**
 * Handle city name input
 */
async function handleCityLocation(chatId, command) {
  const cityName = command.replace(/^city:/i, '').replace(/^cidade:/i, '').trim();

  if (!cityName) {
    await sendTelegramMessage(chatId, '❌ Por favor, digite o nome da cidade.');
    return;
  }

  await sendTelegramMessage(chatId, `🔄 Buscando localização para "${cityName}"...`);

  try {
    const location = await geocodeCity(cityName);

    // Save user location
    saveUserLocation(chatId, location.lat, location.lon, location.name);

    const responseText = `✅ *Localização atualizada!*\n\n📍 ${location.name}\n\nLat: ${location.lat.toFixed(4)}, Lon: ${location.lon.toFixed(4)}`;

    await sendTelegramMessage(chatId, responseText, {
      parse_mode: 'Markdown'
    });

    console.log(`✓ City location saved for ${chatId}: ${location.name}`);
  } catch (error) {
    console.error('ERROR: Failed to geocode city:', error.message);
    await sendTelegramMessage(chatId, `❌ Não foi possível encontrar a cidade "${cityName}". Verifique o nome e tente novamente.`);
  }
}

/**
 * Show help message
 */
async function showHelp(chatId) {
  const helpMessage = `❓ *Ajuda - Perninhasclimabot*

📋 *Comandos Disponíveis:*

/start - Mostrar mensagem de boas-vindas
/menu - Mostrar menu de previsão do tempo
/location - Alterar sua localização
/help - Mostrar esta mensagem

---

📍 *Opções de Localização:*

🗺️ GPS - Compartilhe sua localização precisa
💻 IP - Detecta automaticamente sua localização
✏️ Manual - Digite o nome da sua cidade

---

🌤️ *Tipos de Previsão:*

Hoje - Restante do dia (horas futuras)
Amanhã - Previsão completa de amanhã
Próximos 3 dias - Previsão estendida
Próximos 7 dias - Previsão semanal

---

💬 *Dúvidas?*

Entre em contato com o administrador do bot.`;

  await sendTelegramMessage(chatId, helpMessage, {
    reply_markup: {
      inline_keyboard: [[
        { text: '📅 Voltar ao Menu', callback_data: 'menu' }
      ]]
    },
    parse_mode: 'Markdown'
  });

  console.log('✓ Help message sent');
}

/**
 * Send authorization message
 */
async function sendAuthorizationMessage(chatId, userId) {
  const message = `🔒 *Acesso não autorizado*

Você não está autorizado a usar este bot.

Por favor, entre em contato com o administrador e forneça seu ID de usuário:

\`${userId}\``;

  await sendTelegramMessage(chatId, message, {
    parse_mode: 'Markdown'
  });
}

/**
 * Handle /allow command (admin only)
 */
async function handleAllow(chatId, command) {
  if (chatId !== WEATHER_BOT_ADMIN_ID) {
    await sendTelegramMessage(chatId, '❌ Apenas o administrador pode usar este comando.');
    return;
  }

  const targetId = parseInt(command.split(' ')[1]);
  if (!targetId) {
    await sendTelegramMessage(chatId, '❌ Uso: /allow <chat_id>');
    return;
  }

  const allowedUsers = getAllowedUsers();
  if (allowedUsers.includes(targetId)) {
    await sendTelegramMessage(chatId, `⚠️ Usuário ${targetId} já está autorizado.`);
    return;
  }

  allowedUsers.push(targetId);
  saveAllowedUsers(allowedUsers);

  await sendTelegramMessage(chatId, `✅ Usuário ${targetId} autorizado com sucesso!`);

  console.log(`✓ User ${targetId} authorized by admin ${chatId}`);
}

/**
 * Handle /disallow command (admin only)
 */
async function handleDisallow(chatId, command) {
  if (chatId !== WEATHER_BOT_ADMIN_ID) {
    await sendTelegramMessage(chatId, '❌ Apenas o administrador pode usar este comando.');
    return;
  }

  const targetId = parseInt(command.split(' ')[1]);
  if (!targetId) {
    await sendTelegramMessage(chatId, '❌ Uso: /disallow <chat_id>');
    return;
  }

  const allowedUsers = getAllowedUsers();
  const index = allowedUsers.indexOf(targetId);

  if (index === -1) {
    await sendTelegramMessage(chatId, `⚠️ Usuário ${targetId} não está autorizado.`);
    return;
  }

  if (targetId === WEATHER_BOT_ADMIN_ID) {
    await sendTelegramMessage(chatId, '❌ Você não pode remover sua própria autorização.');
    return;
  }

  allowedUsers.splice(index, 1);
  saveAllowedUsers(allowedUsers);

  await sendTelegramMessage(chatId, `✅ Usuário ${targetId} removido da lista de autorizados.`);

  console.log(`✓ User ${targetId} unauthorized by admin ${chatId}`);
}

/**
 * Handle /listusers command (admin only)
 */
async function handleListUsers(chatId) {
  if (chatId !== WEATHER_BOT_ADMIN_ID) {
    await sendTelegramMessage(chatId, '❌ Apenas o administrador pode usar este comando.');
    return;
  }

  const allowedUsers = getAllowedUsers();

  let message = `📋 *Usuários Autorizados*\n\n`;
  message += `Total: ${allowedUsers.length}\n\n`;
  message += `👤 Admin: \`${WEATHER_BOT_ADMIN_ID}\`\n\n`;
  message += `👥 Usuários:\n`;

  for (const userId of allowedUsers) {
    const location = getUserLocation(userId);
    const locationInfo = location ? ` (${location.name})` : '';
    const isAdmin = userId === WEATHER_BOT_ADMIN_ID ? ' 🔑' : '';
    message += `\n\`${userId}\`${locationInfo}${isAdmin}`;
  }

  await sendTelegramMessage(chatId, message, {
    parse_mode: 'Markdown'
  });

  console.log('✓ Authorized users list sent');
}

/**
 * Check if a user is authorized
 */
function isAuthorized(userId) {
  const allowedUsers = getAllowedUsers();
  return allowedUsers.includes(userId);
}

/**
 * Get list of authorized users
 */
function getAllowedUsers() {
  try {
    const data = fs.readFileSync(ALLOWED_USERS_FILE, 'utf8');
    const json = JSON.parse(data);
    return json.allowed_users || [];
  } catch (error) {
    console.error('ERROR: Failed to read allowed users:', error.message);
    return [WEATHER_BOT_ADMIN_ID];
  }
}

/**
 * Save list of authorized users
 */
function saveAllowedUsers(users) {
  try {
    const data = {
      admin: WEATHER_BOT_ADMIN_ID,
      allowed_users: users
    };
    fs.writeFileSync(ALLOWED_USERS_FILE, JSON.stringify(data, null, 2));
  } catch (error) {
    console.error('ERROR: Failed to save allowed users:', error.message);
  }
}

/**
 * Get user location
 */
function getUserLocation(userId) {
  try {
    const data = fs.readFileSync(USER_LOCATIONS_FILE, 'utf8');
    const json = JSON.parse(data);
    return json[userId] || DEFAULT_LOCATION;
  } catch (error) {
    console.error('ERROR: Failed to read user location:', error.message);
    return DEFAULT_LOCATION;
  }
}

/**
 * Save user location
 */
function saveUserLocation(userId, lat, lon, name) {
  try {
    let data = {};
    try {
      const fileContent = fs.readFileSync(USER_LOCATIONS_FILE, 'utf8');
      data = JSON.parse(fileContent);
    } catch (error) {
      // File doesn't exist or is invalid, start fresh
    }

    data[userId] = {
      lat: lat,
      lon: lon,
      name: name
    };

    fs.writeFileSync(USER_LOCATIONS_FILE, JSON.stringify(data, null, 2));
  } catch (error) {
    console.error('ERROR: Failed to save user location:', error.message);
  }
}

/**
 * Get location name via reverse geocoding
 */
async function getLocationName(lat, lon) {
  return new Promise((resolve, reject) => {
    const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&zoom=10&accept-language=pt-BR`;

    https.get(url, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (json.display_name) {
            // Extract city/state from display name
            const parts = json.display_name.split(',');
            if (parts.length >= 2) {
              resolve(parts.slice(0, 2).join(',').trim());
            } else {
              resolve(json.display_name);
            }
          } else if (json.address) {
            const city = json.address.city || json.address.town || json.address.village || json.address.municipality || '';
            const state = json.address.state || '';
            resolve([city, state].filter(Boolean).join(', '));
          } else {
            resolve('Localização desconhecida');
          }
        } catch (error) {
          reject(error);
        }
      });
    }).on('error', reject);
  });
}

/**
 * Get IP-based location
 */
async function getIPLocation() {
  return new Promise((resolve, reject) => {
    https.get('http://ip-api.com/json/', (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (json.status === 'success') {
            resolve({
              lat: json.lat,
              lon: json.lon,
              name: `${json.city}, ${json.regionName}`
            });
          } else {
            reject(new Error(json.message || 'Failed to get IP location'));
          }
        } catch (error) {
          reject(error);
        }
      });
    }).on('error', reject);
  });
}

/**
 * Geocode city name
 */
async function geocodeCity(cityName) {
  return new Promise((resolve, reject) => {
    const encodedName = encodeURIComponent(cityName);
    const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodedName}&count=1&language=pt&format=json`;

    https.get(url, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (json.results && json.results.length > 0) {
            const result = json.results[0];
            resolve({
              lat: result.latitude,
              lon: result.longitude,
              name: `${result.name}, ${result.country}`
            });
          } else {
            reject(new Error('City not found'));
          }
        } catch (error) {
          reject(error);
        }
      });
    }).on('error', reject);
  });
}

/**
 * Get weather forecast
 */
function getWeatherForecast(type, lat, lon, locationName) {
  return new Promise((resolve, reject) => {
    const scriptPath = '/job/skills/weather-bot/weather.sh';
    const args = [type, lat.toString(), lon.toString(), locationName];

    console.log(`Running forecast script: ${scriptPath} ${args.join(' ')}`);

    const child = spawn(scriptPath, args);

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

/**
 * Answer callback query
 */
async function answerCallbackQuery(callbackId, text = null) {
  const postData = JSON.stringify({ callback_query_id: callbackId, text });

  await makeTelegramRequest('/answerCallbackQuery', postData);
}

/**
 * Send message to Telegram
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
 * Make request to Telegram API
 */
function makeTelegramRequest(method, postData) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.telegram.org',
      port: 443,
      path: `/bot${WEATHER_BOT_TOKEN}${method}`,
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

// Run the handler
handleWeatherBot().catch((error) => {
  console.error('ERROR: Unhandled error:', error);
  process.exit(1);
});
