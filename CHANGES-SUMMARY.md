# Weather Bot Fixes - Changes Summary

## Overview
All three reported problems have been successfully fixed. Here's what was changed and why.

---

## File 1: `skills/weather-bot/weather.sh`

### Change Location: Line 329 (main function)

### What Changed:
```bash
# BEFORE (WRONG - double escapes newlines):
local escaped_message=$(echo "$formatted_message" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g; s/"/\\"/g')

# AFTER (CORRECT - escapes in right order):
local escaped_message=$(echo "$formatted_message" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
```

### Why This Fixes Problem 1:
The old code converted newlines to `\n` first, then escaped backslashes, creating `\\n` (double-escaped).
The new code escapes backslashes first, then converts newlines to `\n`, resulting in proper JSON format.

**Impact:**
- ✅ JSON output now has proper `\n` instead of `\\n`
- ✅ Messages display with actual line breaks in Telegram
- ✅ No more literal `\n` text appearing

---

## File 2: `skills/weather-bot/send-scheduled.sh`

### Change 1: `get_authorized_users()` function (Line 67)

### What Changed:
```bash
# BEFORE (only looked for allowed_users):
jq -r '.allowed_users[]' "$ALLOWED_USERS_FILE"

# AFTER (tries both authorized and allowed_users):
if jq -e '.authorized' "$ALLOWED_USERS_FILE" > /dev/null 2>&1; then
    jq -r '.authorized[]' "$ALLOWED_USERS_FILE"
else
    jq -r '.allowed_users[]' "$ALLOWED_USERS_FILE" 2>/dev/null || echo ""
fi
```

### Why This Fixes Problem 2:
The allowed-users.json file uses `authorized[]` key, not `allowed_users[]`.
The script was failing to find authorized users, leading to incorrect message routing.

**Impact:**
- ✅ Correctly reads user IDs from JSON file
- ✅ Backward compatible with both formats
- ✅ Prevents user lookup failures

---

### Change 2: `get_user_notifications()` function (Line 89)

### What Changed:
```bash
# BEFORE (used @sh format):
jq -r ".\"${user_id}\".notifications // [] | @sh" | tr -d "'"

# AFTER (uses array expansion):
jq -r ".\"${user_id}\".notifications // [] | .[]" | tr '\n' ' '
```

### Why This Fixes Problem 2:
The `@sh` format was hard to parse and could cause matching issues.
The new format outputs clean space-separated values: `"6 10 18 "`

**Impact:**
- ✅ Easier to match hours with `grep -w`
- ✅ More reliable parsing
- ✅ Prevents false matches (e.g., "1" matching "10")

---

### Change 3: `send_telegram_message()` function (Line 126)

### What Changed:
```bash
# BEFORE (incomplete escaping):
local escaped_message=$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')

# AFTER (complete escaping):
local escaped_message=$(echo "$message" | sed \
    -e 's/\\/\\\\/g' \
    -e 's/"/\\"/g' \
    -e ':a;N;$!ba;s/\n/\\n/g' \
    -e 's/\r/\\r/g' \
    -e 's/\t/\\t/g')
```

### Why This Fixes Problem 1:
The old code didn't escape newlines for JSON, causing Telegram API to receive malformed JSON.
The new code properly escapes all special characters including newlines, carriage returns, and tabs.

**Impact:**
- ✅ Valid JSON sent to Telegram API
- ✅ Newlines properly encoded
- ✅ All special characters handled

---

### Change 4: `get_weather_forecast()` function (Line 178)

### What Changed:
```bash
# BEFORE (redundant conversion):
echo "$output" | jq -r '.message' | sed 's/\\n/\n/g'

# AFTER (let jq handle it):
echo "$output" | jq -r '.message'
```

### Why This Improves Code Quality:
jq already converts JSON `\n` to actual newlines. The extra sed was redundant.

**Impact:**
- ✅ Cleaner code
- ✅ Less processing overhead
- ✅ Same correct result

---

### Change 5: Message header formatting (Line 248)

### What Changed:
```bash
# BEFORE (literal \n in string):
final_message="🕐 *Previsão ${HOUR}h00 - ${location_name}*\n\n${forecast_message}"

# AFTER (actual newlines):
final_message=$(printf "🕐 *Previsão %sh00 - %s*\n\n%s" "$HOUR" "$location_name" "$forecast_message")
```

### Why This Fixes Problem 1:
Bash strings with `\n` create literal backslash-n characters.
Using `printf` creates actual newline characters.

**Impact:**
- ✅ Header has actual newlines
- ✅ Proper spacing in messages
- ✅ Consistent formatting

---

## Summary of Fixes

### Problem 1: Literal \n in Messages
**Root Cause:** Double-escaping in weather.sh + incomplete escaping in send-scheduled.sh
**Fixed By:**
1. Correcting sed order in weather.sh
2. Adding newline escaping in send_telegram_message()
3. Using printf for header formatting

### Problem 2: Duplicate/Missing Hours
**Root Cause:** Wrong JSON key + inefficient parsing
**Fixed By:**
1. Supporting both `authorized` and `allowed_users` keys
2. Improving notification parsing to output clean values
3. Ensuring `grep -w` matches correctly

### Problem 3: Partner Links
**Status:** Already correct - no changes needed

---

## Testing Verification

All changes have been tested:
- ✅ JSON format validation
- ✅ Message parsing with actual newlines
- ✅ Header formatting with proper newlines
- ✅ Telegram payload validity
- ✅ User notification matching (6✓, 10✓, 12✗, 18✓)

---

## Deployment Impact

### Files to Deploy:
1. `skills/weather-bot/weather.sh`
2. `skills/weather-bot/send-scheduled.sh`

### Expected Results:
- Messages with proper line breaks
- Correct hour labels (no duplicates or missing hours)
- Partner links working correctly

### No Breaking Changes:
- Backward compatible with old JSON formats
- No API changes
- All features preserved

---

**Changes validated and ready for deployment** ✅
