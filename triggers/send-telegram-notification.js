#!/usr/bin/env node

/**
 * Send Telegram notification for job completion
 * Receives the job payload as a JSON string argument
 * Uses TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID from environment
 */

const https = require('https');

async function sendTelegramNotification() {
  // Get environment variables
  const token = process.env.TELEGRAM_BOT_TOKEN;
  const chatId = process.env.TELEGRAM_CHAT_ID;

  if (!token || !chatId) {
    console.error('ERROR: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set in environment');
    process.exit(1);
  }

  // Get payload from command line argument
  const payloadJson = process.argv[2];
  if (!payloadJson) {
    console.error('ERROR: No payload provided');
    process.exit(1);
  }

  let payload;
  try {
    payload = JSON.parse(payloadJson);
  } catch (error) {
    console.error('ERROR: Failed to parse payload JSON:', error.message);
    process.exit(1);
  }

  // Extract relevant fields (flexible to different payload structures)
  const jobId = payload.job_id || payload.jobId || payload.id || payload.job_uuid || payload.jobUuid || 'Unknown';
  const status = payload.status || payload.state || 'Unknown';
  const prUrl = payload.pr_url || payload.prUrl || payload.pull_request_url || payload.pullRequestUrl || null;
  const branch = payload.branch || payload.ref || payload.job_branch || null;
  const title = payload.title || payload.message || payload.job_title || null;

  // Build emoji based on status
  let emoji = '📋';
  if (status.toLowerCase() === 'success' || status.toLowerCase() === 'completed') {
    emoji = '✅';
  } else if (status.toLowerCase() === 'failed' || status.toLowerCase() === 'error') {
    emoji = '❌';
  } else if (status.toLowerCase() === 'running') {
    emoji = '🔄';
  }

  // Build the message
  let message = `${emoji} Job Notification\n`;
  message += `━━━━━━━━━━━━━━━━━━\n`;
  message += `🆔 Job ID: \`${jobId}\`\n`;
  message += `📊 Status: ${status}\n`;

  if (title) {
    message += `📝 Title: ${title}\n`;
  }

  if (branch) {
    message += `🌿 Branch: \`${branch}\`\n`;
  }

  if (prUrl) {
    message += `🔗 PR: ${prUrl}\n`;
  }

  message += `━━━━━━━━━━━━━━━━━━\n`;
  message += `⏰ ${new Date().toISOString()}`;

  // Prepare API request
  const postData = JSON.stringify({
    chat_id: chatId,
    text: message,
    parse_mode: 'Markdown'
  });

  const options = {
    hostname: 'api.telegram.org',
    port: 443,
    path: `/bot${token}/sendMessage`,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          const response = JSON.parse(data);
          if (response.ok) {
            console.log('✓ Telegram notification sent successfully');
            resolve(response);
          } else {
            console.error('ERROR: Telegram API returned error:', response.description);
            process.exit(1);
          }
        } else {
          console.error(`ERROR: HTTP ${res.statusCode}`, data);
          process.exit(1);
        }
      });
    });

    req.on('error', (error) => {
      console.error('ERROR: Request failed:', error.message);
      process.exit(1);
    });

    req.write(postData);
    req.end();
  });
}

// Run the notification
sendTelegramNotification().catch((error) => {
  console.error('ERROR: Unhandled error:', error);
  process.exit(1);
});
