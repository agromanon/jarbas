# Weather Bot - Correções Aplicadas

## Data: 2026-03-23

---

## ✅ PROBLEMA 1 - CRONS
**Status: JÁ EXISTENTE**

Os 7 crons já estavam configurados corretamente no `config/CRONS.json`:
- `weather-06h` → 6:00
- `weather-08h` → 8:00
- `weather-10h` → 10:00
- `weather-12h` → 12:00
- `weather-14h` → 14:00
- `weather-16h` → 16:00
- `weather-18h` → 18:00

Todos habilitados e apontando para `/app/skills/weather-bot/send-scheduled.sh <hora>`

---

## ✅ PROBLEMA 2 - ARQUIVO DE PREFERÊNCIAS
**Status: CRIADO**

Criado `/job/data/user-preferences.json`:
```json
{
  "5121600266": {
    "notifications": [10, 12, 18]
  }
}
```

Admin configurado para receber notificações às 10h, 12h e 18h.

---

## ✅ PROBLEMA 3 - SISTEMA DE AUTORIZAÇÃO
**Status: CORRIGIDO**

**Causa do Bug:**
O callback handler verificava `isAuthorized()` ANTES de processar callbacks de autorização (`approve_user_`, `deny_user_`). Se o admin não estava na lista de autorizados, ele era bloqueado.

**Correção em `/job/triggers/weather-bot.js`:**
```javascript
// ANTES:
if (!data.startsWith('location_') && !data.startsWith('loc_menu_') && !isAuthorized(userId))

// DEPOIS:
if (!data.startsWith('location_') &&
    !data.startsWith('loc_menu_') &&
    !data.startsWith('approve_user_') &&
    !data.startsWith('deny_user_') &&
    !isAuthorized(userId))
```

**Arquivos de dados criados:**
- `/job/data/allowed-users.json` - Admin (5121600266) adicionado como autorizado

---

## ✅ PROBLEMA 4 - SALVAMENTO DE HORÁRIOS
**Status: VERIFICADO**

O sistema de configuração de horários funciona corretamente:
- Handler: `handleToggleHour()` em `weather-bot.js`
- Arquivo: `/job/data/user-preferences.json`
- Diretório criado automaticamente por `ensureDataDir()`

---

## ✅ PROBLEMA 5 - FORMATAÇÃO DE MENSAGENS
**Status: CORRIGIDO**

**Correções aplicadas:**

1. **`/job/skills/weather-bot/weather.sh`:**
   - Agora usa `jq -Rs '{message: .}'` para escapar JSON corretamente
   - Fallback manual mantido para sistemas sem jq

2. **`/job/skills/weather-bot/send-scheduled.sh`:**
   - Melhorado parsing de JSON com `jq -r '.message'`
   - Fallback manual corrigido para converter `\n` literal em quebras de linha reais

3. **`/job/triggers/weather-bot.js`:**
   - Removido replace redundante `replace(/\\n/g, '\n')`
   - `JSON.parse()` já converte escapes corretamente

---

## ✅ PROBLEMA 6 - LINKS DO PARCEIRO
**Status: JÁ CORRETO**

A função `showPartnerInfo()` já usa Markdown correto:
```javascript
[📱 WhatsApp: (11) 99134‑6681](https://wa.me/5511991346681)
[📸 Instagram: @clinica.myshape](https://www.instagram.com/clinica.myshape)
```

---

## Arquivos Modificados/Criados

| Arquivo | Ação |
|---------|------|
| `/job/data/allowed-users.json` | CRIADO |
| `/job/data/user-preferences.json` | CRIADO |
| `/job/data/user-locations.json` | CRIADO |
| `/job/triggers/weather-bot.js` | MODIFICADO (autorização + newlines) |
| `/job/skills/weather-bot/weather.sh` | MODIFICADO (JSON escaping) |
| `/job/skills/weather-bot/send-scheduled.sh` | MODIFICADO (newline handling) |

---

## Teste Realizado

```bash
WEATHER_BOT_TOKEN="..." bash /job/skills/weather-bot/send-scheduled.sh 18
```

**Resultado:**
```
✓ Message sent to 5121600266
Total users: 1
Successful: 1
Failed: 0
```

---

## Próximos Passos

1. **Deploy:** Fazer commit e push das mudanças
2. **Reiniciar container:** O container precisa reiniciar para carregar os novos arquivos
3. **Testar autorização:** Pedir para alguém solicitar acesso e verificar se o admin consegue aprovar
4. **Testar formatação:** Verificar se as mensagens automáticas chegam com quebras de linha corretas
