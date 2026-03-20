# Telegram Notification Debug Report

**Date:** 2026-03-20T16:27:00Z
**Job ID:** telegram-debug

---

## Executive Summary

**Issue:** Event handler returns `{"ok":true,"notified":true}` but Telegram messages do not arrive.

**Likely Root Causes:**
1. **Silent API failures** - Telegram API call is made but errors are caught and swallowed
2. **Missing error handling** - No try/catch or response validation around Telegram API calls
3. **Async/await issue** - API call is not awaited, or promise rejection is not handled
4. **Environment variable not loaded** - TELEGRAM_CHAT_ID may not be read correctly at runtime
5. **Rate limiting or timeout** - API call times out without throwing an error

---

## How the Event Handler Sends Telegram Notifications

### 1. Notification Flow

Based on the GitHub workflow analysis:

```
GitHub Actions (notify-pr-complete.yml)
    ↓
POST /api/github/webhook (with job completion data)
    ↓
Event Handler (thepopebot npm package)
    ↓
1. Validate GH_WEBHOOK_SECRET
    ↓
2. Create notification record in database
    ↓
3. If TELEGRAM_CHAT_ID is set:
    - Format message (HTML or plain text)
    - Call Telegram API
    - Update notification status
    ↓
4. Return {"ok":true,"notified":true}
```

### 2. Telegram API Call Pattern (Expected)

The event handler should be using the Telegram Bot API:

```javascript
// Expected implementation (in thepopebot package)
const https = require('https');

function sendTelegramMessage(chatId, botToken, message) {
  const payload = JSON.stringify({
    chat_id: chatId,
    text: message,
    parse_mode: 'HTML',
    disable_web_page_preview: true
  });

  const options = {
    hostname: 'api.telegram.org',
    path: `/bot${botToken}/sendMessage`,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload)
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const response = JSON.parse(data);
        if (response.ok) {
          resolve(response);
        } else {
          reject(new Error(response.description));
        }
      });
    });

    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}
```

### 3. Required Variables

| Variable | Purpose | Source | Required for Notifications |
|----------|---------|--------|---------------------------|
| `TELEGRAM_BOT_TOKEN` | Bot token from @BotFather | `.env` | ✅ Yes |
| `TELEGRAM_CHAT_ID` | Target chat for notifications | `.env` | ✅ Yes |
| `APP_URL` | Public URL (not used for sending) | `.env` | ❌ No |
| `GH_WEBHOOK_SECRET` | Webhook validation | GitHub Secret | ✅ Yes |

---

## Why Notifications Might Fail Silently

### Hypothesis 1: Unhandled Promise Rejection

**Problem:** API call is made but promise is not awaited or caught.

```javascript
// BAD CODE (likely the issue)
async function sendNotification(job) {
  await createNotification(job);

  // Telegram call is fire-and-forget
  sendTelegramMessage(chatId, token, message); // ❌ No await, no catch

  return { ok: true, notified: true }; // Returns immediately
}
```

**Result:**
- Function returns `notified: true` immediately
- Telegram API call happens in background
- If it fails, no error is thrown or logged

**Fix:**
```javascript
// GOOD CODE
async function sendNotification(job) {
  await createNotification(job);

  if (TELEGRAM_CHAT_ID && TELEGRAM_BOT_TOKEN) {
    try {
      await sendTelegramMessage(chatId, token, message);
      return { ok: true, notified: true };
    } catch (error) {
      console.error('Telegram notification failed:', error);
      return { ok: true, notified: false, error: error.message };
    }
  }

  return { ok: true, notified: false };
}
```

### Hypothesis 2: Swallowed Errors in Try/Catch

**Problem:** Telegram API call is wrapped in try/catch but error is only logged.

```javascript
// BAD CODE
async function sendNotification(job) {
  await createNotification(job);

  if (TELEGRAM_CHAT_ID && TELEGRAM_BOT_TOKEN) {
    try {
      await sendTelegramMessage(chatId, token, message);
    } catch (error) {
      // Error is logged but not propagated
      console.error('Telegram error:', error); // ❌ Logged but ignored
    }
  }

  return { ok: true, notified: true }; // Always returns true
}
```

**Result:**
- Errors are caught and logged (but may be in a log level that's not visible)
- Function still returns `notified: true`
- No way to know if notification actually succeeded

**Fix:**
```javascript
// GOOD CODE
async function sendNotification(job) {
  await createNotification(job);

  let notified = false;
  let error = null;

  if (TELEGRAM_CHAT_ID && TELEGRAM_BOT_TOKEN) {
    try {
      const response = await sendTelegramMessage(chatId, token, message);
      notified = response.ok;
    } catch (error) {
      error = error.message;
      console.error('Telegram notification failed:', error);
    }
  }

  return { ok: true, notified, error };
}
```

### Hypothesis 3: No Response Validation

**Problem:** HTTP request completes but response body is not validated.

```javascript
// BAD CODE
function sendTelegramMessage(chatId, botToken, message) {
  return new Promise((resolve) => {
    const req = https.request(options, (res) => {
      // ❌ No check of response.ok or res.statusCode
      resolve(); // Always resolves
    });
    req.write(payload);
    req.end();
  });
}
```

**Result:**
- Promise resolves even if Telegram returns error (e.g., invalid chat_id)
- Caller thinks notification succeeded
- No way to detect API errors

**Fix:**
```javascript
// GOOD CODE
function sendTelegramMessage(chatId, botToken, message) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const response = JSON.parse(data);
        if (response.ok) {
          resolve(response);
        } else {
          // ✅ Reject on API error
          reject(new Error(`Telegram API error (${response.error_code}): ${response.description}`));
        }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}
```

### Hypothesis 4: Environment Variable Not Loaded

**Problem:** `TELEGRAM_CHAT_ID` is in `.env` but not read at runtime.

```javascript
// BAD CODE
// Using process.env directly without loading from .env
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID; // ❌ May be undefined
```

**Result:**
- If `.env` is not loaded before Node.js starts, variables won't be available
- Docker Compose should load `.env`, but timing issues can occur
- Chat works because it's initiated by Telegram, not by environment variable

**Fix:**
```javascript
// GOOD CODE
// Ensure dotenv is loaded early
import 'dotenv/config';
// Or use a config loader that validates required vars
```

### Hypothesis 5: Silent Timeouts

**Problem:** Request times out but no timeout handler is set.

```javascript
// BAD CODE
function sendTelegramMessage(chatId, botToken, message) {
  return new Promise((resolve) => {
    const req = https.request(options, (res) => {
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve());
    });
    // ❌ No timeout set
    req.write(payload);
    req.end();
  });
}
```

**Result:**
- If Telegram API is slow or unreachable, request hangs
- Promise never resolves or rejects
- Function may timeout at a higher level but logs nothing

**Fix:**
```javascript
// GOOD CODE
function sendTelegramMessage(chatId, botToken, message) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve());
    });
    req.on('error', reject);

    // ✅ Set timeout
    req.setTimeout(10000, () => {
      req.destroy();
      reject(new Error('Telegram API timeout'));
    });

    req.write(payload);
    req.end();
  });
}
```

---

## Telegram API Endpoint and Payload

### Endpoint

```
POST https://api.telegram.org/bot{BOT_TOKEN}/sendMessage
```

### Request Headers

```
Content-Type: application/json
Content-Length: {length of payload}
```

### Request Body

```json
{
  "chat_id": "123456789",
  "text": "<b>Job Completed</b>\n\nJob ID: test-123\nStatus: ✅ Success",
  "parse_mode": "HTML",
  "disable_web_page_preview": true
}
```

### Success Response (200 OK)

```json
{
  "ok": true,
  "result": {
    "message_id": 12345,
    "from": {
      "id": 987654321,
      "is_bot": true,
      "first_name": "Test Bot",
      "username": "test_bot"
    },
    "chat": {
      "id": 123456789,
      "first_name": "User",
      "type": "private"
    },
    "date": 1679012345,
    "text": "Job Completed..."
  }
}
```

### Error Response (200 OK but with error)

```json
{
  "ok": false,
  "error_code": 400,
  "description": "Bad Request: chat not found"
}
```

### Common Error Codes

| Code | Description | Likely Cause |
|------|-------------|--------------|
| 400 | Bad Request: chat not found | Invalid `chat_id` |
| 403 | Forbidden: bot was blocked by the user | User blocked the bot |
| 429 | Too Many Requests: retry after X seconds | Rate limiting |
| 500 | Internal Server Error | Telegram API issue |

---

## Testing the Telegram API Directly

### Test Script Location

A test script has been created at `/tmp/test-telegram-api.js` that verifies:

1. ✅ Bot token is valid (`getMe`)
2. ✅ Chat ID is valid (`getChat`)
3. ✅ Can send HTML-formatted messages
4. ✅ Can send plain text messages

### Running the Test

```bash
# From the event handler server (not the Docker agent)
cd /path/to/event-handler
export TELEGRAM_BOT_TOKEN="your_bot_token"
export TELEGRAM_CHAT_ID="your_chat_id"
node /tmp/test-telegram-api.js
```

### Expected Output

```
=== Telegram API Test ===

Configuration:
  Bot Token: 1234567890:ABC...
  Chat ID: 123456789

Test 1: Get bot info (getMe)
  Status Code: 200
  Bot: @your_bot
  Can send messages: true
  ✅ SUCCESS

Test 2: Get chat info (getChat)
  Status Code: 200
  Chat Type: private
  Chat Title: (private chat)
  Can send messages: true
  ✅ SUCCESS - Chat ID is valid

Test 3: Basic sendMessage with HTML formatting
  Status Code: 200
  Response: {...}
  ✅ SUCCESS - Message sent

Test 4: Plain text message (no formatting)
  Status Code: 200
  ✅ SUCCESS

=== All Tests Passed ===
```

---

## Why Chat Works but Notifications Don't

### Telegram Chat (User → Bot)

- **Initiated by:** User sends message to bot
- **Telegram endpoint:** Webhook URL configured via `setWebhook`
- **Required vars:** `TELEGRAM_BOT_TOKEN`, `TELEGRAM_WEBHOOK_SECRET`, `APP_URL`
- **Flow:**
  1. User sends "hello" to bot
  2. Telegram POSTs to `${APP_URL}/api/telegram/webhook`
  3. Event handler receives message (chat_id included in payload)
  4. Event handler processes and responds (POST to Telegram API with same chat_id)
- **Why it works:** The chat_id comes from the incoming message, not from env vars

### Job Completion Notifications (Bot → User)

- **Initiated by:** Event handler after receiving GitHub webhook
- **Required vars:** `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` (⚠️ CRITICAL)
- **Flow:**
  1. GitHub sends webhook to `${APP_URL}/api/github/webhook`
  2. Event handler creates notification in database
  3. Event handler reads `TELEGRAM_CHAT_ID` from env
  4. Event handler POSTs to Telegram API with `chat_id` from env
- **Why it might fail:**
  - `TELEGRAM_CHAT_ID` is not loaded from `.env`
  - `TELEGRAM_CHAT_ID` is wrong (e.g., string vs number)
  - API call is made but errors are swallowed
  - API call is not awaited (fire-and-forget)

**Key Difference:** Chat receives `chat_id` from Telegram; notifications must use `chat_id` from environment.

---

## Recommended Debugging Steps

### Step 1: Verify Environment Variables

```bash
# From the event handler container
docker exec event-handler env | grep TELEGRAM

# Expected output:
# TELEGRAM_BOT_TOKEN=1234567890:ABC...
# TELEGRAM_CHAT_ID=123456789
# TELEGRAM_WEBHOOK_SECRET=... (if using webhooks)
```

If `TELEGRAM_CHAT_ID` is missing, the issue is confirmed: the variable is not being loaded.

### Step 2: Test Telegram API Directly

Run the test script from Step 1 above to verify the API works outside the event handler.

### Step 3: Check Event Handler Logs

```bash
# Look for Telegram-related errors
docker logs event-handler 2>&1 | grep -i telegram

# Look for any errors during notification processing
docker logs event-handler 2>&1 | grep -i notify

# If nothing is found, errors may be swallowed or logged at a different level
```

### Step 4: Enable Debug Logging (if possible)

If the event handler supports debug logging, enable it to see the actual Telegram API calls.

### Step 5: Add Test Notification Endpoint

Create a test endpoint that forces a Telegram notification and logs everything:

```javascript
// Test endpoint (if you can modify thepopebot code)
app.post('/api/test-telegram', async (req, res) => {
  console.log('=== Telegram Test Notification ===');
  console.log('TELEGRAM_BOT_TOKEN:', process.env.TELEGRAM_BOT_TOKEN?.substring(0, 10));
  console.log('TELEGRAM_CHAT_ID:', process.env.TELEGRAM_CHAT_ID);

  try {
    const result = await sendTelegramMessage(
      process.env.TELEGRAM_CHAT_ID,
      process.env.TELEGRAM_BOT_TOKEN,
      'Test notification from debug endpoint'
    );
    console.log('Telegram API response:', result);
    res.json({ ok: true, result });
  } catch (error) {
    console.error('Telegram API error:', error);
    res.status(500).json({ ok: false, error: error.message });
  }
});
```

Call it with:
```bash
curl -X POST https://your-app-url/api/test-telegram \
  -H "Content-Type: application/json"
```

---

## Conclusion

The most likely cause of `{"ok":true,"notified":true}` with no actual Telegram message is **silent API failures** due to:

1. **Unhandled promise rejection** - API call not awaited
2. **Swallowed errors** - Caught but only logged, not propagated
3. **No response validation** - Success returned even on API error
4. **Missing error logging** - Errors logged at a level that's not visible

**To Fix:**
1. Verify `TELEGRAM_CHAT_ID` is loaded in the event handler container
2. Run the test script to confirm the API works
3. Check event handler logs for any Telegram errors
4. If code is accessible, add proper error handling and logging
5. Consider adding a test endpoint to force notifications and debug

**Test Script Available:** `/tmp/test-telegram-api.js`

---

**Status:** 🔍 Analysis complete - Multiple hypotheses documented
**Next Action:** Verify environment variables and run test script
