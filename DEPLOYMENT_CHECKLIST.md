# Weather Forecast - Deployment Checklist

## Pre-Deployment Checklist

### 1. Environment Variables ✅ Required
Make sure these are set in `.env`:
- [ ] `TELEGRAM_BOT_TOKEN` - From @BotFather
- [ ] `TELEGRAM_CHAT_ID` - Your chat ID
- [ ] `APP_URL` - Your public URL (e.g., https://your-bot.example.com)

**Check:**
```bash
echo $TELEGRAM_BOT_TOKEN
echo $TELEGRAM_CHAT_ID
echo $APP_URL
```

### 2. File Permissions ✅ Required
- [ ] `/job/skills/weather-forecast/forecast.sh` - Executable
- [ ] `/job/triggers/handle-telegram-weather.js` - Executable
- [ ] `/job/setup-weather-webhook.sh` - Executable
- [ ] `/job/integration-test.sh` - Executable

**Check:**
```bash
ls -l /job/skills/weather-forecast/forecast.sh
ls -l /job/triggers/handle-telegram-weather.js
```

### 3. Configuration Files ✅ Required
- [ ] `config/TRIGGERS.json` - Contains telegram-weather trigger
- [ ] `config/CRONS.json` - Contains weather-morning and weather-lunch
- [ ] `package.json` - Contains setup-weather script

**Check:**
```bash
cat config/TRIGGERS.json | jq '.[] | select(.name == "telegram-weather")'
cat config/CRONS.json | jq '.[] | select(.name | contains("weather"))'
```

### 4. Documentation ✅ Optional
- [ ] `/job/docs/WEATHER_SETUP.md` - Setup guide
- [ ] `/job/docs/WEATHER_QUICK_REFERENCE.md` - Quick reference
- [ ] `/job/README_WEATHER.md` - Feature README

## Deployment Steps

### Step 1: Run Integration Tests
```bash
cd /job
./integration-test.sh
```

**Expected output:** All tests pass ✅

### Step 2: Test Forecast Script
```bash
# Test all forecast types
node test-weather-handler.js

# Test individual types
skills/weather-forecast/forecast.sh today true
skills/weather-forecast/forecast.sh tomorrow true
skills/weather-forecast/forecast.sh 3days true
skills/weather-forecast/forecast.sh 7days true
```

**Expected output:** JSON with forecast message ✅

### Step 3: Set Up Telegram Webhook
```bash
npm run setup-weather
```

**Expected output:** "✓ Telegram webhook configured successfully!" ✅

### Step 4: Verify Webhook
```bash
curl "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo"
```

**Expected:** Webhook URL set to `${APP_URL}/api/telegram/weather` ✅

### Step 5: Test in Telegram
1. Open Telegram and send `/tempo` to your bot
2. You should see an inline keyboard with 4 options:
   - 🌅 Hoje (restante do dia)
   - 🌅 Amanhã
   - 📅 Próximos 3 dias
   - 📆 Próximos 7 dias
3. Click each button and verify forecasts arrive

**Expected:** All buttons work and send forecasts ✅

### Step 6: Verify Cron Jobs
Check that the weather cron jobs are running:
- [ ] 6:00 AM - Morning forecast arrives
- [ ] 12:00 PM - Lunchtime forecast arrives

**Check in web UI:** Go to `/crons` and verify jobs are enabled ✅

## Post-Deployment Verification

### 1. Check Logs
```bash
# Check logs in the web UI at /notifications
# Or check the server logs for any errors
```

**Expected:** No errors in weather handler or forecast script ✅

### 2. Test Time Filtering
Send `/tempo` and click "Hoje". Verify:
- [ ] Forecast starts from current hour (not earlier)
- [ ] Forecast ends at 6 PM (18h00)

**Example:** If it's 11 AM, forecast should show 11 AM, 12 PM, etc. ✅

### 3. Test All Forecast Types
- [ ] Hoje: Shows today's forecast from current hour
- [ ] Amanhã: Shows tomorrow's full day (8 AM - 6 PM)
- [ ] Próximos 3 dias: Shows 3 full days
- [ ] Próximos 7 dias: Shows 7 full days

**Expected:** All types work correctly ✅

### 4. Test Callback Handling
- [ ] Clicking buttons stops the loading animation
- [ ] Forecast arrives as a new message
- [ ] No errors in logs

**Expected:** Smooth user experience ✅

## Troubleshooting

### Webhook Not Set Up
**Symptoms:** Commands don't respond, no menu appears

**Solutions:**
1. Run `npm run setup-weather`
2. Check `APP_URL` is correct in `.env`
3. Check `TELEGRAM_BOT_TOKEN` is valid

### Forecasts Not Arriving
**Symptoms:** Commands respond but no forecasts sent

**Solutions:**
1. Check `TELEGRAM_CHAT_ID` is correct
2. Run integration test: `./integration-test.sh`
3. Check logs for errors

### Time Filtering Not Working
**Symptoms:** Shows past hours for "today"

**Solutions:**
1. Check `TIMEZONE` in `forecast.sh` is "America/Sao_Paulo"
2. Verify system time is correct
3. Test manually: `skills/weather-forecast/forecast.sh today true`

### Cron Jobs Not Running
**Symptoms:** No automatic forecasts at 6 AM and 12 PM

**Solutions:**
1. Check jobs are enabled in `/crons` web UI
2. Check CRONS.json has `"enabled": true`
3. Verify event handler is running

## Rollback Plan

If issues arise, you can:
1. Remove the telegram-weather trigger from TRIGGERS.json
2. Revert forecast.sh to original (if backup exists)
3. Set webhook back to original: `/api/telegram/webhook`

## Success Criteria

Deployment is successful when:
- ✅ All integration tests pass
- ✅ `/tempo` command shows inline keyboard
- ✅ All 4 forecast buttons work
- ✅ Forecasts arrive in Telegram
- ✅ Time filtering works correctly
- ✅ Cron jobs send forecasts at 6 AM and 12 PM
- ✅ No errors in logs

## Support Resources

- Setup Guide: `/job/docs/WEATHER_SETUP.md`
- Quick Reference: `/job/docs/WEATHER_QUICK_REFERENCE.md`
- Implementation Details: `/job/docs/WEATHER_IMPLEMENTATION_SUMMARY.md`
- Feature README: `/job/README_WEATHER.md`
- Test Suite: `/job/integration-test.sh`

## Version

Weather Forecast Enhancement v1.0.0
Implemented: 2025-03-21
Status: ✅ Production Ready
