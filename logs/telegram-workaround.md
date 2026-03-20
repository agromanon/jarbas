# Telegram Notification Workaround

## Overview

The built-in Telegram notification in thepopebot has a bug where it returns `"notified": true` but doesn't actually send messages. This workaround creates a direct Telegram notification system using a webhook trigger that calls the Telegram API directly.

## How It Works

### Components

1. **Trigger**: `job-complete-telegram` in `config/TRIGGERS.json`
   - Watches for POST requests to `/webhook/job-complete`
   - Executes a command that sends the notification

2. **Script**: `triggers/send-telegram-notification.js`
   - Receives job payload via command line argument
   - Formats a nice message with job details
   - Calls Telegram Bot API using environment variables

### Message Format

The notification includes:
- Emoji based on job status (✅ success, ❌ failed, 🔄 running, 📋 other)
- Job ID
- Status
- Title (if available)
- Branch (if available)
- PR URL (if available)
- Timestamp

Example:
```
✅ Job Notification
━━━━━━━━━━━━━━━━━━
🆔 Job ID: `abc123-def456`
📊 Status: success
📝 Title: Analyze the logs and write a summary
🌿 Branch: `job/abc123-def456`
🔗 PR: https://github.com/owner/repo/pull/123
━━━━━━━━━━━━━━━━━━
⏰ 2026-03-20T16:56:52.000Z
```

## Configuration

### Required Environment Variables

These must be set in your `.env` file:

```bash
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=123456789
```

- **TELEGRAM_BOT_TOKEN**: Your Telegram bot token from [@BotFather](https://t.me/botfather)
- **TELEGRAM_CHAT_ID**: The chat ID to send notifications to (can be a user or group)

### Getting Your Telegram Bot Token

1. Start a chat with [@BotFather](https://t.me/botfather) on Telegram
2. Send `/newbot` and follow the prompts
3. Copy the token (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)
4. Add it to your `.env` file as `TELEGRAM_BOT_TOKEN`

### Getting Your Chat ID

#### For a personal chat:
1. Start a chat with your bot
2. Visit: `https://api.telegram.org/bot<TOKEN>/getUpdates`
3. Replace `<TOKEN>` with your actual bot token
4. Look for `"chat":{"id":123456789,...}` in the response
5. Use that number as your `TELEGRAM_CHAT_ID`

#### For a group/channel:
1. Add your bot to the group/channel
2. Send a message to the group
3. Visit: `https://api.telegram.org/bot<TOKEN>/getUpdates`
4. Look for the chat ID (group IDs are usually negative numbers, e.g., `-1001234567890`)

## Usage

### Sending a Notification

Send a POST request to the webhook:

```bash
curl -X POST https://your-domain.com/webhook/job-complete \
  -H "Content-Type: application/json" \
  -d '{
    "job_id": "abc123-def456",
    "status": "success",
    "title": "Analyze the logs and write a summary",
    "branch": "job/abc123-def456",
    "pr_url": "https://github.com/owner/repo/pull/123"
  }'
```

### From GitHub Actions

Add this step to your workflow after the job completes:

```yaml
- name: Notify Telegram
  run: |
    curl -X POST ${{ secrets.APP_URL }}/webhook/job-complete \
      -H "Content-Type: application/json" \
      -d '{
        "job_id": "${{ github.run_id }}",
        "status": "${{ job.status }}",
        "title": "${{ github.event.head_commit.message }}",
        "branch": "${{ github.ref_name }}",
        "pr_url": "${{ steps.create_pr.outputs.pr_url }}"
      }'
```

### Payload Format

The webhook accepts a flexible JSON payload. Supported fields:

| Field | Description | Examples |
|-------|-------------|----------|
| `job_id`, `jobId`, `id`, `job_uuid`, `jobUuid` | Job identifier | `"abc123-def456"` |
| `status`, `state` | Job status | `"success"`, `"failed"`, `"running"` |
| `title`, `message`, `job_title` | Job description | `"Analyze the logs"` |
| `branch`, `ref`, `job_branch` | Git branch | `"job/abc123-def456"` |
| `pr_url`, `prUrl`, `pull_request_url`, `pullRequestUrl` | Pull request URL | `"https://github.com/..."` |

All fields are optional - the script will use `"Unknown"` for missing values.

## Testing

Test your setup:

```bash
curl -X POST http://localhost:3000/webhook/job-complete \
  -H "Content-Type: application/json" \
  -d '{
    "job_id": "test-job-001",
    "status": "success",
    "title": "Test notification from webhook",
    "branch": "test-branch"
  }'
```

Check the script output:
- Success: `✓ Telegram notification sent successfully`
- Error: Check for missing environment variables or invalid API response

## Troubleshooting

### "TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set"
- Ensure both variables are in your `.env` file
- Restart the Docker container after adding them

### "Failed to parse payload JSON"
- Ensure your POST body is valid JSON
- Use `Content-Type: application/json` header

### "HTTP 401 Unauthorized"
- Check that `TELEGRAM_BOT_TOKEN` is correct
- Verify the token hasn't been revoked

### "HTTP 400 Bad Request: chat not found"
- Verify `TELEGRAM_CHAT_ID` is correct
- Ensure your bot has been added to the group/channel (if using a group)
- Start a chat with your bot first (if using personal chat)

### "HTTP 409 Conflict: bot was blocked by the user"
- The user has blocked the bot
- Unblock the bot in Telegram privacy settings

## Integration with GitHub Actions Workflows

### Example: Custom Job Completion Notification

Create a new GitHub Actions workflow file (e.g., `.github/workflows/notify-telegram.yml`):

```yaml
name: Notify Telegram on Job Complete

on:
  workflow_run:
    workflows: ["run-job"]
    types: [completed]
    branches: ["job/*"]

jobs:
  notify:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    steps:
      - name: Send Telegram Notification
        run: |
          curl -X POST ${{ secrets.APP_URL }}/webhook/job-complete \
            -H "Content-Type: application/json" \
            -d '{
              "job_id": "${{ github.event.workflow_run.id }}",
              "status": "${{ github.event.workflow_run.conclusion }}",
              "title": "Job completed via workflow",
              "branch": "${{ github.event.workflow_run.head_branch }}",
              "pr_url": "https://github.com/${{ github.repository }}/pulls/${{ github.event.workflow_run.pull_requests[0].number }}"
            }'
```

### Alternative: Modify Existing Workflow

Add a notification step to your existing `.github/workflows/run-job.yml`:

```yaml
# After the agent runs and creates a PR
- name: Notify Telegram
  if: success()
  run: |
    curl -X POST ${{ secrets.APP_URL }}/webhook/job-complete \
      -H "Content-Type: application/json" \
      -d '{
        "job_id": "${{ github.run_number }}",
        "status": "success",
        "title": "Agent job completed successfully",
        "branch": "${{ github.ref_name }}"
      }'
```

## Security Considerations

1. **Environment Variables**: `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` are in `.env` and not exposed to the agent
2. **Webhook Path**: The webhook path `/webhook/job-complete` is public, but the script validates payload structure
3. **Rate Limiting**: Telegram has API rate limits; avoid sending too many notifications in quick succession

## Maintenance

- **Script Location**: `/job/triggers/send-telegram-notification.js`
- **Trigger Config**: `config/TRIGGERS.json` (entry: `job-complete-telegram`)
- **Logs**: Check container logs for output from the script
- **Upgrades**: This workaround uses `command` type which is not affected by package upgrades

## Future Improvements

- Add retry logic for failed API calls
- Support rich formatting with buttons/inline keyboard
- Add image/file attachment support
- Add filtering rules (only notify on certain job types)
- Add rate limiting to avoid Telegram API bans
- Add message templates per job type

## Related Files

- `config/TRIGGERS.json` - Trigger configuration
- `triggers/send-telegram-notification.js` - Notification script
- `.env` - Environment variables (TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID)
