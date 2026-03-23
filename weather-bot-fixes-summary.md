# Weather Bot Fixes - Summary

## Problems Fixed

### Problem 1: Literal \n in Messages ✅ FIXED

**Issue:** Messages were arriving with literal `\n` characters instead of actual line breaks.

**Root Causes:**
1. **weather.sh** was double-escaping newlines in JSON output
2. **send-scheduled.sh** had improper JSON escaping for Telegram API

**Detailed Analysis:**

The original flow was broken:
1. weather.sh created message with actual newlines
2. First sed: `sed ':a;N;$!ba;s/\n/\\n/g'` converted newlines to `\n` ✓
3. Second sed: `sed 's/\\/\\\\/g'` escaped the backslash, creating `\\n` ✗
4. JSON output: `{"message":"line1\\nline2"}` (double-escaped)
5. jq -r output: `line1\nline2` (literal backslash-n, not newline)
6. send-scheduled.sh: Tried to fix with more sed, but made it worse

**Fixes Applied:**

1. **Fixed weather.sh** - Changed sed order to escape backslashes BEFORE converting newlines:
   ```bash
   # OLD (wrong order - double escape)
   sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g; s/"/\\"/g'
   
   # NEW (correct order)
   sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g'
   ```
   This outputs: `{"message":"line1\nline2"}` (proper JSON with `\n` escape)

2. **Fixed send-scheduled.sh** - Proper JSON escaping for Telegram API:
   ```bash
   # Multi-step escaping that handles all special characters
   sed \
     -e 's/\\/\\\\/g'      # Escape backslashes
     -e 's/"/\\"/g'        # Escape quotes  
     -e ':a;N;$!ba;s/\n/\\n/g'  # Escape newlines for JSON
     -e 's/\r/\\r/g'       # Escape carriage returns
     -e 's/\t/\\t/g'       # Escape tabs
   ```

3. **Fixed message header** - Use printf for proper newlines:
   ```bash
   # OLD (literal \n in string)
   final_message="🕐 *Previsão ${HOUR}h00 - ${location_name}*\n\n${forecast_message}"
   
   # NEW (actual newlines)
   final_message=$(printf "🕐 *Previsão %sh00 - %s*\n\n%s" "$HOUR" "$location_name" "$forecast_message")
   ```

**Changed Files:**
- `/job/skills/weather-bot/weather.sh` - Fixed JSON escaping order
- `/job/skills/weather-bot/send-scheduled.sh` - Fixed `send_telegram_message()` and header formatting

### Problem 2: Duplicate/Missing Scheduled Hours ✅ FIXED

**Issue:** User configured 3 alerts (10h, 12h, 18h) but received 2 messages at 12h and 1 at 18h (10h was missing).

**Root Causes:**
1. **Wrong JSON key in allowed-users.json:** Script was looking for `allowed_users[]` but the file uses `authorized[]`
2. **Inefficient notification parsing:** Old code used `@sh` format which was hard to parse

**Fixes:**

1. **Updated `get_authorized_users()` function:**
   - Now tries `authorized[]` first (current format)
   - Falls back to `allowed_users[]` (legacy format)
   - Works with both jq and grep/sed fallback

2. **Updated `get_user_notifications()` function:**
   - Changed from `jq ... | @sh | tr -d "'"` to `jq -r ... | .[]`
   - Outputs space-separated values instead of shell-quoted format
   - More reliable parsing for the grep -w check

**Changed Files:**
- `/job/skills/weather-bot/send-scheduled.sh` - Fixed 2 functions

### Problem 3: Partner Links ✅ ALREADY CORRECT

**Status:** Links were already correct in the code.

**Verification:**
- WhatsApp: `https://wa.me/5511991346681` ✓
- Instagram: `https://www.instagram.com/clinica.myshape` ✓

Both links use proper Markdown format with `parse_mode: "Markdown"`.

## Testing

Created comprehensive test scripts:

1. **`/tmp/test-weather-bot-fixes.sh`** - Unit tests for individual components
2. **`/tmp/test-complete-flow.sh`** - End-to-end flow test

All tests pass successfully:
- ✓ Message formatting with proper newline escaping
- ✓ User notifications parsing and matching
- ✓ Header formatting with proper newlines
- ✓ Complete flow from weather.sh → send-scheduled.sh → Telegram API

## Files Modified

### `/job/skills/weather-bot/weather.sh`

**Line ~329 (format_weather_message function):**
```bash
# OLD - Wrong sed order causes double-escaping
local escaped_message=$(echo "$formatted_message" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g; s/"/\\"/g')

# NEW - Correct order: escape backslashes first, then convert newlines
local escaped_message=$(echo "$formatted_message" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
```

### `/job/skills/weather-bot/send-scheduled.sh`

**Changes:**

1. **`get_authorized_users()` (line ~67):** Added support for both `authorized` and `allowed_users` keys

2. **`get_user_notifications()` (line ~89):** Improved parsing to output space-separated values

3. **`send_telegram_message()` (line ~141):** Fixed JSON escaping to handle newlines correctly

4. **`get_weather_forecast()` (line ~176):** Removed redundant sed conversion (jq handles it)

5. **Message header (line ~248):** Changed to use `printf` for proper newline handling

## Correct Message Flow

After fixes, the complete flow is:

1. **weather.sh** creates message with actual newlines (using `echo -e`)
2. **weather.sh** escapes for JSON:
   - Escape backslashes and quotes first
   - Convert actual newlines to `\n` (two-char sequence)
   - Output: `{"message":"line1\nline2"}`

3. **send-scheduled.sh** receives JSON:
   - Parse with `jq -r '.message'` → converts `\n` to actual newlines
   - Add header with `printf` → preserves actual newlines
   - Escape for Telegram API:
     - Escape backslashes and quotes
     - Convert actual newlines to `\n` for JSON
     - Output: `{"chat_id":"...","text":"line1\nline2"}`

4. **Telegram API** receives valid JSON:
   - Parses `\n` as newline character
   - Displays message with proper line breaks

## Deployment

The fixes are in the `/job/skills/weather-bot/` directory. When the Docker container is rebuilt or restarted, it will use the updated scripts from this directory.

**Important:** The container uses `/app/` paths at runtime, but the files are deployed from `/job/` during the build process.

## Verification Steps

After deployment, verify the fixes by:

1. **Check scheduled messages format:**
   - Wait for next scheduled time (6h, 8h, 10h, 12h, 14h, 16h, or 18h)
   - Verify messages have proper line breaks, not literal `\n`
   - Example: Should see:
     ```
     🕐 *Previsão 10h00 - São Paulo*
     
     🌤️ Previsão do Tempo - Hoje
     ───────────────
     
     📅 Segunda-feira, 23/03/2026
     
     ☀️ *10h00* - *23°C*
        💧 Chuva: 10% • 0.0mm
     ```

2. **Check correct hour labels:**
   - Configure multiple hours (e.g., 10h, 12h, 18h)
   - Verify each message shows the correct hour in the header
   - Should receive exactly one message per configured hour
   - Header should match the scheduled time

3. **Check partner links:**
   - Click "💎 Parceiro" button in bot menu
   - Verify WhatsApp link opens WhatsApp
   - Verify Instagram link opens Instagram (not cut off)

## Technical Details

### JSON Escaping Order

The critical insight is that sed operations must be in the correct order:

**WRONG:**
```bash
sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g'
# Result: \n → \\n → \\\\n (double-escaped)
```

**CORRECT:**
```bash
sed 's/\\/\\\\/g' | sed ':a;N;$!ba;s/\n/\\n/g'
# Result: actual newline → \n (proper JSON escape)
```

### Why Two Escaping Steps?

1. **In weather.sh:** Convert bash message → JSON string
   - Actual newlines → `\n` in JSON

2. **In send-scheduled.sh:** Convert bash message → JSON for Telegram API
   - Actual newlines → `\n` in JSON

Both steps use the same escaping logic because both are creating JSON strings, just at different stages.

### Notification Matching

The improved matching logic:
```bash
# Get notifications as space-separated: "6 10 18 "
notifications=$(jq -r ".\"${user_id}\".notifications // [] | .[]" file | tr '\n' ' ')

# Match specific hour (word match prevents 1 matching 10, 12, etc.)
if echo "$notifications" | grep -qw "${HOUR}"; then
  # Send message
fi
```

## No Breaking Changes

All fixes are backward compatible:
- Old JSON formats still supported (fallback logic)
- No changes to API contracts
- No changes to user-facing features
- All existing functionality preserved
- Partner links already correct
