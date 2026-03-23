# Deployment Checklist - Weather Bot Fixes

## Pre-Deployment ✅

- [x] All problems investigated and root causes identified
- [x] Fixes implemented in `/job/skills/weather-bot/`
- [x] Automated tests created and passing
- [x] Documentation created

## Files Changed ✅

- [x] `/job/skills/weather-bot/weather.sh` - Fixed JSON escaping
- [x] `/job/skills/weather-bot/send-scheduled.sh` - Fixed 5 functions

## Deployment Steps

### Option 1: Restart Container
```bash
# SSH into server
cd /path/to/thepopebot
docker-compose restart
```

### Option 2: Rebuild Container
```bash
# SSH into server
cd /path/to/thepopebot
docker-compose down
docker-compose up -d --build
```

## Post-Deployment Verification

### 1. Check Container Logs
```bash
docker logs <container-name> | grep -i weather
```

### 2. Wait for Next Scheduled Time
- Check at next hour mark (6h, 8h, 10h, 12h, 14h, 16h, or 18h)
- Verify message format has proper line breaks
- Verify correct hour label in header

### 3. Test Manual Forecast
- Send `/start` to bot
- Click "Ver Previsão" → "Hoje"
- Verify message formatting

### 4. Test Partner Links
- Click "💎 Parceiro" button
- Verify WhatsApp link works
- Verify Instagram link works

### 5. Test Configuration
- Click "⚙️ Configurar horários"
- Select hours: 10h, 12h, 18h
- Save configuration
- Verify at next scheduled times

## Expected Results

### ✅ Message Format
```
🕐 Previsão 10h00 - Location

🌤️ Previsão do Tempo - Hoje
───────────────

📅 Date

☀️ Hour - Temp
   💧 Rain info
```

### ✅ Scheduled Messages
- Exactly ONE message per configured hour
- Correct hour label (10h, 12h, 18h)
- No duplicates
- No missing hours

### ✅ Partner Links
- WhatsApp: Opens direct chat
- Instagram: Opens full profile

## Troubleshooting

### If messages still have literal \n:
1. Check container is using new files: `docker exec <container> ls -la /app/skills/weather-bot/`
2. Verify file timestamps are recent
3. Restart container again

### If wrong hours are sent:
1. Check user-preferences.json format: `docker exec <container> cat /app/data/user-preferences.json`
2. Verify format: `{"USER_ID":{"notifications":[10,12,18]}}`
3. Check logs for parsing errors

### If container won't start:
1. Check logs: `docker logs <container>`
2. Verify syntax: `bash -n /job/skills/weather-bot/*.sh`
3. Check file permissions

## Rollback Plan

If issues occur:

```bash
# Restore old files from git
cd /job
git checkout HEAD -- skills/weather-bot/weather.sh
git checkout HEAD -- skills/weather-bot/send-scheduled.sh

# Restart container
docker-compose restart
```

## Success Criteria

- [ ] Messages have proper line breaks (not literal \n)
- [ ] Each scheduled hour sends ONE message
- [ ] Hour labels are correct (match scheduled time)
- [ ] Partner links work correctly
- [ ] No errors in container logs
- [ ] User reports issue is resolved

## Contact

If issues persist after deployment:
1. Check container logs for errors
2. Run test scripts: `/tmp/final-verification.sh`
3. Review detailed documentation in `/job/FIXES-APPLIED.md`

---

**Deployed by:** ___________________ Date: _________
**Verified by:** ___________________ Date: _________
