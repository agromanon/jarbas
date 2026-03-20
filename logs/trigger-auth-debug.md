# Webhook Trigger Authentication Debug Report

**Date**: 2026-03-20  
**Issue**: Webhook trigger at `/webhook/job-complete` redirects to `/login` instead of processing the request

---

## Executive Summary

Webhook triggers defined in `config/TRIGGERS.json` use paths like `/webhook/job-complete`, which are **NOT under `/api/`** and therefore go through the Next.js middleware that requires authentication. Since webhook triggers are designed to receive external webhooks without authentication, this creates a conflict.

---

## Architecture Analysis

### 1. Middleware Flow

The middleware is imported from the `thepopebot` package:

```javascript
// /job/middleware.js
export { middleware, config } from 'thepopebot/middleware';
```

This middleware applies authentication checks to all routes that don't explicitly bypass them.

### 2. Route Structure

**API Routes** (under `/api/`):
- `/api/[...thepopebot]/route.js` - Catch-all handler for API routes
- Requires authentication via `x-api-key` header or webhook secrets
- Handles: `/api/create-job`, `/api/telegram/webhook`, `/api/github/webhook`, etc.

**Webhook Trigger Paths** (NOT under `/api/`):
- `/webhook/job-complete`
- `/webhook/github-push`
- `/webhook` (catch-all)
- These paths go through Next.js routing, NOT the API route handler

### 3. Authentication Requirements

From the documentation:

| Route Type | Authentication | Method |
|------------|---------------|--------|
| API Routes (`/api/*`) | Required | `x-api-key` header or webhook secrets |
| Web Interface (`/`, `/admin`, etc.) | Required | Session (cookie) |
| Webhook Triggers (`/webhook/*`) | **Expected to be public** | None (but middleware enforces auth) |

---

## The Problem

When a POST request is sent to `/webhook/job-complete`:

```
POST /webhook/job-complete
Headers: Content-Type: application/json
Body: { ... }
```

1. **Route Resolution**: The path `/webhook/job-complete` does NOT match `/api/*`
2. **Middleware Application**: The middleware from `thepopebot/middleware` is applied
3. **Authentication Check**: Middleware requires authentication
4. **Redirect**: Since no authentication is provided, redirects to `/login`
5. **Result**: Webhook trigger never executes

---

## Evidence

### From Documentation

**`telegram-workaround.md`** explicitly states:
> **Webhook Path**: The webhook path `/webhook/job-complete` is public, but the script validates payload structure

This confirms that webhook triggers are **intended to be public**.

**API Endpoints Table** from `CLAUDE.md`:
```markdown
All API routes are under `/api/`, handled by the catch-all route.

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/api/create-job` | POST | `x-api-key` | Create a new autonomous agent job |
| `/api/telegram/webhook` | POST | `TELEGRAM_WEBHOOK_SECRET` | Telegram bot webhook |
| `/api/github/webhook` | POST | `GH_WEBHOOK_SECRET` | Receive notifications from GitHub Actions |
| `/api/ping` | GET | Public | Health check |
```

Note: `/webhook/*` paths are NOT in this table - they are separate from API routes.

### Current Configuration

**`config/TRIGGERS.json`**:
```json
[
  {
    "name": "job-complete-telegram",
    "watch_path": "/webhook/job-complete",
    "actions": [
      { 
        "type": "command", 
        "command": "node send-telegram-notification.js '{{body}}'" 
      }
    ],
    "enabled": true
  }
]
```

---

## Comparison: How Other Triggers Handle Auth

### Built-in Telegram Webhook

**Path**: `/api/telegram/webhook`  
**Auth**: `TELEGRAM_WEBHOOK_SECRET` (header validation)  
**Route Type**: API route (under `/api/`)

### Built-in GitHub Webhook

**Path**: `/api/github/webhook`  
**Auth**: `GH_WEBHOOK_SECRET` (header validation)  
**Route Type**: API route (under `/api/`)

### Custom Webhook Triggers

**Path**: `/webhook/*` (configurable in `TRIGGERS.json`)  
**Auth**: **None intended**  
**Route Type**: Next.js page route (NOT API route)

---

## Root Cause

**Middleware applies authentication to all non-API routes by default.**

The middleware from `thepopebot/middleware` has logic that:
1. Checks if the route is under `/api/`
2. If yes, applies API-specific auth checks (x-api-key or webhook secrets)
3. If no, applies session-based auth (requires login)

Webhook trigger paths (`/webhook/*`) fall into category #3, causing the redirect to `/login`.

---

## Potential Solutions

### Option 1: Use API Key Authentication (Immediate Workaround)

Call webhook triggers with an `x-api-key` header:

```bash
curl -X POST https://your-domain.com/webhook/job-complete \
  -H "Content-Type: application/json" \
  -H "x-api-key: tpb_YOUR_API_KEY_HERE" \
  -d '{ ... }'
```

**Pros**: Works immediately with current system  
**Cons**: Requires generating API key in web UI; external services need access to key

### Option 2: Move Webhook Triggers Under `/api/` (Architectural Fix)

Change trigger paths to `/api/webhook/*`:

```json
{
  "watch_path": "/api/webhook/job-complete"
}
```

**Pros**: Aligns with API route architecture; can use webhook secrets  
**Cons**: May require changes to thepopebot package to handle custom webhook paths

### Option 3: Configure Middleware to Bypass Auth for Webhook Paths

Add configuration to bypass auth for `/webhook/*` paths:

**In middleware configuration** (would require package update):
```javascript
export const config = {
  matcher: [
    // Exclude webhook paths from auth
    '/((?!api/webhook|webhook|_next/static|_next/image|favicon.ico).*)',
  ],
}
```

**Pros**: Maintains public access to webhook triggers  
**Cons**: Requires package update; potential security concern if webhook paths are not rate-limited

### Option 4: Add Webhook Secret Validation to Trigger Paths

Implement secret validation for webhook trigger paths:

```bash
curl -X POST https://your-domain.com/webhook/job-complete \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: YOUR_SECRET_HERE" \
  -d '{ ... }'
```

**Pros**: Provides security without requiring login  
**Cons**: Requires package update to implement custom header validation

---

## Recommendations

### Immediate Workaround (Use Option 1)

1. Generate an API key from the web UI (Settings > Secrets)
2. Use the API key when calling webhook triggers:

```bash
curl -X POST https://your-domain.com/webhook/job-complete \
  -H "Content-Type: application/json" \
  -H "x-api-key: tpb_YOUR_API_KEY_HERE" \
  -d '{
    "job_id": "test-001",
    "status": "success",
    "title": "Test notification"
  }'
```

### Long-Term Fix (Requires Package Update)

The thepopebot package should be updated to:
1. Either configure middleware to bypass auth for `/webhook/*` paths
2. Or implement webhook secret validation for custom trigger paths
3. Or move webhook trigger handling under `/api/` for consistency

### Security Considerations

**If webhook paths are made public:**
- Implement rate limiting to prevent abuse
- Add IP whitelist options for webhook sources
- Consider adding optional webhook secret validation
- Monitor webhook logs for suspicious activity

---

## Testing Steps

### Test Current Behavior (Expected: 302 Redirect)

```bash
curl -v -X POST http://localhost:3000/webhook/job-complete \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

Expected: HTTP 302 redirect to `/login`

### Test with API Key (Expected: 200 OK)

```bash
curl -v -X POST http://localhost:3000/webhook/job-complete \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{"test": "data"}'
```

Expected: HTTP 200 OK (or trigger executes)

### Test API Route for Comparison

```bash
curl -v -X POST http://localhost:3000/api/ping
```

Expected: HTTP 200 OK (public endpoint, no auth required)

---

## Files Referenced

- `/job/middleware.js` - Middleware configuration
- `/job/config/TRIGGERS.json` - Webhook trigger definitions
- `/job/app/api/[...thepopebot]/route.js` - API route handler
- `/job/triggers/send-telegram-notification.js` - Example webhook script
- `/job/docs/CRONS_AND_TRIGGERS.md` - Triggers documentation
- `/job/docs/SECURITY.md` - Security documentation
- `/job/logs/telegram-workaround.md` - Workaround documentation

---

## Conclusion

The issue is a **design mismatch**: webhook trigger paths are intended to be public (for external webhook consumption), but the middleware applies session authentication to all non-API routes. The immediate workaround is to use an API key when calling webhook triggers. A proper fix requires updating the thepopebot package to either:
1. Bypass authentication for `/webhook/*` paths, or
2. Implement webhook secret validation for custom triggers, or
3. Move webhook trigger handling under `/api/` for consistency with built-in webhooks.
