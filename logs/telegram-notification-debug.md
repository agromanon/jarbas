# Telegram Notification Debug Report

**Date:** 2026-03-20T16:15:00Z
**Job ID:** telegram-notification-debug

---

## Executive Summary

**Root Cause:** Telegram notifications for job completions require the `TELEGRAM_CHAT_ID` environment variable to be configured in the event handler. Without this variable, job completion notifications are created in the web UI but are not sent to Telegram.

---

## Job Completion Notification Flow

### 1. GitHub Actions Workflow

When a job completes, the following sequence occurs:

1. **Job Agent** (`run-job.yml`) completes and creates a PR
2. **Auto-Merge** (`auto-merge.yml`) attempts to merge the PR
3. **Notify Event Handler** (`notify-pr-complete.yml`) triggers on workflow completion
   - Gathers job details (job description, commit message, changed files, PR status)
   - Sends POST request to `${APP_URL}/api/github/webhook` with payload:
     ```json
     {
       "job_id": "...",
       "branch": "job/...",
       "status": "completed",
       "job": "...",
       "run_url": "...",
       "pr_url": "...",
       "changed_files": [...],
       "commit_message": "...",
       "commit_sha": "...",
       "merge_result": "merged"
     }
     ```

### 2. Event Handler Processing

The event handler (code in `thepopebot` npm package) processes the webhook:

- Validates the `GH_WEBHOOK_SECRET` header
- Creates a notification record in the database
- **If `TELEGRAM_CHAT_ID` is configured**, sends a message to Telegram
- Updates the web UI with the notification

---

## Required Configuration

### For Job Completion Notifications to Work

| Variable | Purpose | Required |
|----------|---------|----------|
| `APP_URL` | Public URL for webhooks | ✅ Yes |
| `GH_WEBHOOK_SECRET` | Secret for GitHub webhook validation | ✅ Yes |
| `TELEGRAM_BOT_TOKEN` | Bot token from @BotFather | ✅ Yes |
| `TELEGRAM_CHAT_ID` | Target chat ID for notifications | ✅ **Yes (for Telegram)** |

### For Telegram Chat to Work

| Variable | Purpose | Required |
|----------|---------|----------|
| `APP_URL` | Public URL for webhooks | ✅ Yes |
| `TELEGRAM_BOT_TOKEN` | Bot token from @BotFather | ✅ Yes |
| `TELEGRAM_WEBHOOK_SECRET` | Secret for validating Telegram webhooks | ✅ Yes |

---

## What's Missing

**Missing Configuration:** `TELEGRAM_CHAT_ID`

### Why Telegram Chat Works but Job Notifications Don't

- **Telegram Chat** (bot responding to messages): Requires `TELEGRAM_BOT_TOKEN` and `TELEGRAM_WEBHOOK_SECRET`. The bot receives messages directly from users via the Telegram webhook.

- **Job Completion Notifications**: The event handler **initiates** the Telegram message after receiving the GitHub webhook. To send a message, it needs to know **where** to send it — the `TELEGRAM_CHAT_ID` tells it which chat to notify.

### The Gap

The `TELEGRAM_CHAT_ID` variable is documented as "For Telegram" (not marked as required), which suggests:
- Telegram is optional (you can use the agent without it)
- But if you want Telegram notifications, you **must** configure this variable
- Without it, notifications only appear in the web UI (`/notifications`)

---

## How to Fix

### Option 1: Get Your Chat ID and Set `TELEGRAM_CHAT_ID`

1. **Find your Telegram chat ID:**
   ```bash
   # Option A: Use @userinfobot (simplest)
   # 1. Open Telegram and search for @userinfobot
   # 2. Start the bot
   # 3. It will reply with your numeric chat ID

   # Option B: Check event handler logs
   # 1. Send a message to your bot
   # 2. Check the event handler logs for the incoming webhook
   # 3. Look for "chat_id" in the payload
   ```

2. **Add `TELEGRAM_CHAT_ID` to `.env`:**
   ```bash
   # In .env (on the event handler server)
   TELEGRAM_CHAT_ID=123456789
   ```

3. **Restart the event handler:**
   ```bash
   # If using Docker Compose
   docker compose restart event-handler

   # Or if running directly
   npm run build
   pm2 restart thepopebot
   ```

### Option 2: Run the Telegram Setup Wizard

The setup wizard (`npm run setup-telegram`) can configure all Telegram settings, including the chat ID:

```bash
npm run setup-telegram
```

This wizard will:
1. Prompt for your bot token
2. Set up the webhook
3. Prompt you to send a verification message
4. Extract your chat ID from the message
5. Save `TELEGRAM_CHAT_ID` to `.env`

### Option 3: Use Verification Code (Alternative Method)

The `.env` includes a `TELEGRAM_VERIFICATION` variable that can be used to associate a chat ID:

1. Set a verification code in `.env`:
   ```bash
   TELEGRAM_VERIFICATION=verify-abc12345
   ```

2. Send a message to your bot with that code:
   ```
   verify-abc12345
   ```

3. The event handler will automatically associate your chat ID with the code and save it

---

## Security Considerations

From `docs/SECURITY.md`:

> **Restrict Telegram** — Set `TELEGRAM_CHAT_ID` to your personal chat ID

This is a security feature:
- Without `TELEGRAM_CHAT_ID`, anyone could theoretically send messages to your bot (if they knew the token)
- With `TELEGRAM_CHAT_ID` set, only notifications are sent to that specific chat
- This prevents unauthorized users from receiving your notifications

---

## Verification Steps

After configuring `TELEGRAM_CHAT_ID`, verify that job completion notifications work:

1. **Create a test job:**
   ```bash
   curl -X POST https://your-app-url/api/create-job \
     -H "Content-Type: application/json" \
     -H "x-api-key: YOUR_API_KEY" \
     -d '{"job": "This is a test to verify Telegram notifications"}'
   ```

2. **Wait for the job to complete** (check `/runners` in the web UI)

3. **Check Telegram:**
   - You should receive a message about the completed job
   - The message should include the job ID, status, and a link to the PR

4. **Check the web UI:**
   - Go to `/notifications`
   - Verify the notification appears there too

---

## Additional Notes

### Notification Sources

Notifications can come from multiple sources:

| Source | Triggers | Requires `TELEGRAM_CHAT_ID`? |
|--------|----------|-------------------------------|
| Job completions | `notify-pr-complete.yml` | ✅ Yes |
| Cron jobs | Job completes via agent | ✅ Yes |
| Webhook triggers | Job completes via agent | ✅ Yes |
| Direct chat | User sends message | ❌ No (bot replies directly) |

### Troubleshooting

If notifications still don't work after setting `TELEGRAM_CHAT_ID`:

1. **Check environment variables:**
   ```bash
   # Verify the variable is set
   echo $TELEGRAM_CHAT_ID

   # Check Docker container env (if using Docker)
   docker exec event-handler env | grep TELEGRAM
   ```

2. **Check event handler logs:**
   ```bash
   # Look for Telegram-related errors
   docker logs event-handler | grep -i telegram
   ```

3. **Verify the bot can send messages:**
   - Manually test the bot API
   ```bash
   curl -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
     -d "chat_id=$TELEGRAM_CHAT_ID" \
     -d "text=Test message"
   ```

4. **Check GitHub Actions logs:**
   - Verify `notify-pr-complete.yml` ran successfully
   - Check that the webhook to `${APP_URL}/api/github/webhook` was sent

---

## Conclusion

**The issue is that `TELEGRAM_CHAT_ID` is not configured.** This variable is required for the event handler to send Telegram notifications for job completions, even though Telegram chat works for direct messages.

**Fix:** Set `TELEGRAM_CHAT_ID` in the event handler's `.env` file and restart the event handler.

---

**Status:** 🔍 Root cause identified
**Next Action:** Configure `TELEGRAM_CHAT_ID` and restart event handler
