# Perninhasclimabot - Bot de Previsão do Tempo

Bot dedicado do Telegram para previsão do tempo com sistema de autorização de usuários e gerenciamento de localização.

## 📋 Visão Geral

O **Perninhasclimabot** é um bot independente do Telegram especializado em fornecer previsões do tempo com as seguintes características:

- ✅ Menu interativo com botões inline
- ✅ Sistema de autorização de usuários (admin-controlado)
- ✅ Gerenciamento de localização por usuário (GPS, IP, manual)
- ✅ Múltiplos períodos de previsão (hoje, amanhã, 3 dias, 7 dias)
- ✅ Previsões agendadas (manhã e almoço)
- ✅ Filtro inteligente de horários (apenas horas futuras)
- ✅ Timezone configurável (America/Sao_Paulo)

## 🚀 Configuração Rápida

### 1. Variáveis de Ambiente

Adicione ao arquivo `.env`:

```bash
# Weather Bot Configuration
WEATHER_BOT_TOKEN=8748218290:AAH0ht_meMiVa2U4zSDVOtFrZkyvOt_85x0
WEATHER_BOT_ADMIN_ID=5121600266
```

### 2. Configurar Webhook

Execute o script de setup:

```bash
./setup-weather-bot-webhook.sh
```

Ou manualmente:

```bash
curl -X POST "https://api.telegram.org/bot8748218290:AAH0ht_meMiVa2U4zSDVOtFrZkyvOt_85x0/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://jarbas.polvify.app/api/webhook/weather-bot",
    "allowed_updates": ["message", "callback_query"]
  }'
```

### 3. Testar o Bot

Envie `/start` para [@Perninhasclimabot](https://t.me/Perninhasclimabot) no Telegram.

## 📂 Estrutura de Arquivos

```
/job/
├── skills/
│   └── weather-bot/              # Skill do Weather Bot
│       ├── SKILL.md              # Documentação do skill
│       ├── weather.sh            # Script de previsão do tempo
│       └── send-daily.sh         # Script para previsões agendadas
├── triggers/
│   └── weather-bot.js            # Handler do Telegram
├── data/
│   ├── allowed-users.json        # Base de usuários autorizados
│   └── user-locations.json      # Localizações dos usuários
├── config/
│   ├── TRIGGERS.json             # Configuração do trigger webhook
│   └── CRONS.json                # Jobs agendados
├── skills/active/
│   └── weather-bot -> ../weather-bot  # Symlink para ativar skill
├── setup-weather-bot-webhook.sh  # Script de setup do webhook
└── test-weather-bot.sh           # Script de testes
```

## 💬 Comandos do Bot

### Comandos de Usuário

| Comando | Descrição |
|---------|-----------|
| `/start` | Mostrar mensagem de boas-vindas e status de autorização |
| `/menu` | Mostrar menu de previsão do tempo |
| `/location` | Alterar sua localização |
| `/help` | Mostrar mensagem de ajuda |

### Comandos de Admin

| Comando | Descrição |
|---------|-----------|
| `/allow <chat_id>` | Autorizar um usuário a acessar o bot |
| `/disallow <chat_id>` | Remover autorização de um usuário |
| `/listusers` | Listar todos os usuários autorizados |

### Opções de Localização

1. **📍 GPS** - Compartilhar localização precisa via Telegram
2. **💻 IP** - Detectar automaticamente via endereço IP
3. **✏️ Manual** - Digitar o nome da cidade

## 🌤️ Tipos de Previsão

| Opção | Descrição | Horas |
|-------|-----------|-------|
| Hoje | Previsão do restante do dia | Apenas horas ≥ hora atual |
| Amanhã | Previsão completa de amanhã | Todas as horas do dia |
| Próximos 3 dias | Previsão estendida | 3 dias completos |
| Próximos 7 dias | Previsão semanal | 7 dias completos |

Horário exibido: 08:00 às 18:00 (configurável)

## 📊 Sistema de Autorização

### Arquivo: `data/allowed-users.json`

```json
{
  "admin": 5121600266,
  "allowed_users": [5121600266, 123456789]
}
```

- O admin sempre tem acesso
- Usuários não autorizados recebem mensagem solicitando autorização
- Apenas o admin pode gerenciar usuários autorizados

## 🗺️ Sistema de Localização

### Arquivo: `data/user-locations.json`

```json
{
  "5121600266": {
    "lat": -23.55,
    "lon": -46.70,
    "name": "São Paulo Zona Oeste"
  },
  "123456789": {
    "lat": -22.90,
    "lon": -43.17,
    "name": "Rio de Janeiro, RJ, Brazil"
  }
}
```

### Localização Padrão

Se o usuário não configurou uma localização:
- Nome: São Paulo Zona Oeste
- Latitude: -23.55
- Longitude: -46.70

### Métodos de Geolocalização

1. **Reverse Geocoding (OpenStreetMap/Nominatim)**
   - URL: `https://nominatim.openstreetmap.org/reverse`
   - Usado para: GPS e IP location

2. **IP Geolocation (ipinfo.io)**
   - URL: `https://ipinfo.io/json`
   - Detecta localização baseada no IP do usuário

3. **City Geocoding (Open-Meteo)**
   - URL: `https://geocoding-api.open-meteo.com/v1/search`
   - Busca cidades por nome

## ⏰ Previsões Agendadas

### Configuração Cron

O bot envia previsões automáticas em dois horários:

**Manhã (06:00)**:
```json
{
  "name": "weather-bot-morning",
  "schedule": "0 6 * * *",
  "type": "command",
  "command": "skills/weather-bot/send-daily.sh"
}
```

**Almoço (12:00)**:
```json
{
  "name": "weather-bot-lunch",
  "schedule": "0 12 * * *",
  "type": "command",
  "command": "skills/weather-bot/send-daily.sh"
}
```

### Como Funciona

1. O script `send-daily.sh` lê a lista de usuários autorizados
2. Para cada usuário, obtém sua localização configurada
3. Busca a previsão do dia (hoje) para sua localização
4. Envia a previsão via Telegram

## 🧪 Testes

Execute o script de testes para verificar a instalação:

```bash
./test-weather-bot.sh
```

O script verifica:
- ✅ Existência dos arquivos do skill
- ✅ Permissões de execução
- ✅ Arquivos de configuração
- ✅ Symlink do skill ativado
- ✅ Configuração do trigger e cron
- ✅ Funcionalidade do script weather.sh

## 🔧 Scripts Principais

### weather.sh

Script principal de previsão do tempo.

**Uso:**
```bash
./weather.sh <tipo> <lat> <lon> <nome_local>
```

**Parâmetros:**
- `tipo`: today, tomorrow, 3days, 7days
- `lat`: latitude (ex: -23.55)
- `lon`: longitude (ex: -46.70)
- `nome_local`: nome legível da localização

**Saída:**
```json
{
  "message": "🌤️ Previsão do Tempo - Hoje - São Paulo Zona Oeste\n\n..."
}
```

### send-daily.sh

Script para enviar previsões agendadas a todos os usuários autorizados.

**Uso:**
```bash
./send-daily.sh
```

**Requerimentos:**
- `WEATHER_BOT_TOKEN` definido como variável de ambiente
- Arquivos `allowed-users.json` e `user-locations.json` existentes

### weather-bot.js

Handler do Telegram que processa mensagens e callbacks.

**Funcionalidades:**
- Processa comandos de texto (`/start`, `/menu`, etc.)
- Processa callbacks de botões inline
- Gerencia autorização de usuários
- Gerencia localizações de usuários
- Chama o script `weather.sh` para obter previsões

## 📡 API do Telegram

### Webhook Endpoint

```
POST /api/webhook/weather-bot
```

O webhook recebe atualizações do Telegram e as passa para o handler.

### Atualizações Suportadas

- **messages**: Mensagens de texto e compartilhamento de localização
- **callback_queries**: Cliques em botões inline

### Bot API Methods Usados

- `sendMessage` - Enviar mensagens para o chat
- `answerCallbackQuery` - Responder a cliques em botões
- `setWebhook` - Configurar webhook

## 🌍 APIs Externas

### Open-Meteo Weather API

- **URL**: `https://api.open-meteo.com/v1/forecast`
- **Endpoint**: Previsão horária com temperatura e precipitação
- **Parâmetros**:
  - `latitude`, `longitude`
  - `hourly=temperature_2m,precipitation_probability,precipitation`
  - `timezone=America/Sao_Paulo`
  - `forecast_days=8`

### OpenStreetMap Nominatim (Reverse Geocoding)

- **URL**: `https://nominatim.openstreetmap.org/reverse`
- **Uso**: Obter nome do local a partir de coordenadas

### ipinfo.io (IP Geolocation)

- **URL**: `https://ipinfo.io/json`
- **Uso**: Detectar localização via IP do usuário

### Open-Meteo Geocoding API

- **URL**: `https://geocoding-api.open-meteo.com/v1/search`
- **Uso**: Buscar cidades por nome

## 🛠️ Solução de Problemas

### Bot não responde

1. Verifique se o webhook está configurado corretamente:
   ```bash
   curl "https://api.telegram.org/bot<WEATHER_BOT_TOKEN>/getWebhookInfo"
   ```

2. Verifique os logs do evento handler

3. Verifique se o trigger está habilitado em `config/TRIGGERS.json`

### Usuário não autorizado

1. Verifique se o usuário está em `data/allowed-users.json`
2. Use `/listusers` para ver a lista de usuários autorizados
3. Use `/allow <chat_id>` para autorizar um usuário

### Previsão não enviada

1. Verifique se o script `weather.sh` está funcionando:
   ```bash
   ./skills/weather-bot/weather.sh today -23.55 -46.70 "Teste"
   ```

2. Verifique se o usuário tem uma localização configurada em `data/user-locations.json`

3. Verifique se `WEATHER_BOT_TOKEN` está definido

### Localização não detectada

1. Verifique a conectividade com APIs externas
2. Tente usar um método diferente (GPS, IP, ou manual)
3. Verifique os logs para erros de API

## 📝 Exemplos de Uso

### Exemplo 1: Obter Previsão do Dia

Usuário envia: `/menu`

Bot responde com botões inline:
```
🌅 Hoje              🌅 Amanhã
📅 Próximos 3 dias    📆 Próximos 7 dias
```

Usuário clica em "Hoje"

Bot envia:
```
🌤️ Previsão do Tempo - Hoje - São Paulo Zona Oeste
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 Sexta-feira, 21/03/2026

☀️ 14h00 - 28°C Chuva: 5% 💧0.0mm
⛅ 15h00 - 27°C Chuva: 25% 💧0.0mm
🌦️ 16h00 - 26°C Chuva: 45% 💧0.5mm
🌧️ 17h00 - 25°C Chuva: 75% 💧2.3mm
🌧️ 18h00 - 24°C Chuva: 85% 💧3.1mm

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Exemplo 2: Alterar Localização

Usuário envia: `/location`

Bot responde com opções:
```
🗺️ Alterar Localização

Localização atual: São Paulo Zona Oeste

Escolha como deseja definir sua localização:

📍 Enviar Localização (GPS)
💻 Usar Localização por IP
✏️ Digitar Cidade
```

Usuário escolhe "Enviar Localização (GPS)" e compartilha sua localização

Bot confirma:
```
✅ Localização atualizada!

📍 Rio de Janeiro, RJ, Brazil

Lat: -22.9068, Lon: -43.1729
```

### Exemplo 3: Admin Autorizar Usuário

Admin envia: `/allow 123456789`

Bot confirma:
```
✅ Usuário 123456789 autorizado com sucesso!
```

## 📞 Suporte

Para dúvidas ou problemas:
- Entre em contato com o administrador do bot
- Verifique o arquivo `data/allowed-users.json` para obter o ID do admin
- ID do Admin: `5121600266`

## 📄 Licença

Este bot faz parte do projeto thepopebot.

---

**Bot**: [@Perninhasclimabot](https://t.me/Perninhasclimabot)
**Admin ID**: 5121600266
**Token**: 8748218290:AAH0ht_meMiVa2U4zSDVOtFrZkyvOt_85x0
