---
name: ai-opportunity-radar
description: Radar automatizado de oportunidades de IA/SaaS para o mercado brasileiro. Coleta produtos de múltiplas fontes, analisa viabilidade e envia relatório via Telegram.
---

# AI Opportunity Radar

Radar automatizado que monitora tendências globais de IA/SaaS e identifica oportunidades específicas para o mercado brasileiro.

## ⚡ Quick Start

**Status**: ✅ Funcionando (testado em 2026-03-24)

1. **Configure os GitHub Secrets** (obrigatório para uso automático):
   ```
   AGENT_LLM_RADAR_TELEGRAM_BOT_TOKEN=8470965695:AAHOOrl_o0K8bWHgT9ZyQt53eSjeKgZEZMM
   AGENT_LLM_RADAR_TELEGRAM_CHAT_ID=5121600266
   ```

2. **Verifique a configuração**:
   ```bash
   bash skills/ai-opportunity-radar/verify-config.sh
   ```

3. **Execute o radar**:
   ```bash
   bash skills/ai-opportunity-radar/radar.sh
   ```

📖 **Guia completo de configuração**: [SETUP.md](SETUP.md)

## Funcionalidades

- **Coleta multi-fonte**: There's An AI For That, Product Hunt, Reddit, Future Tools
- **Análise completa**: Score ponderado com 9 critérios (0-100)
- **Filtros eliminatórios**: Remove produtos inviáveis automaticamente
- **Análise de Mar Azul**: Investiga concorrência no Brasil
- **Relatório formatado**: Envia TOP 10 oportunidades via Telegram

## Uso

```bash
# Executar radar completo (coleta + análise + envio)
skills/ai-opportunity-radar/radar.sh

# Apenas coletar dados
skills/ai-opportunity-radar/radar.sh --collect-only

# Apenas analisar dados já coletados
skills/ai-opportunity-radar/radar.sh --analyze-only

# Analisar arquivo específico de produtos
skills/ai-opportunity-radar/radar.sh --input /path/to/products.json

# Apenas enviar relatório existente
skills/ai-opportunity-radar/radar.sh --send-only /path/to/report.md
```

## Estrutura

```
skills/ai-opportunity-radar/
├── SKILL.md              # Esta documentação
├── radar.sh              # Script principal de orquestração
├── analyze.sh            # Análise e scoring de produtos
├── telegram.sh           # Envio de relatório via Telegram
├── diagnose.sh           # Diagnóstico de problemas
├── test-telegram.sh      # Teste de conexão Telegram
├── find-chat-id.sh       # Descobrir chat_id correto
└── sources/
    ├── theresanaiforthat.sh  # Coleta do There's An AI For That
    ├── producthunt.sh        # Coleta do Product Hunt
    ├── reddit.sh             # Coleta do Reddit
    └── futuretools.sh        # Coleta do Future Tools
```

## Critérios de Análise

| Critério | Peso | O que avaliar |
|----------|------|---------------|
| Viabilidade Solo Founder | 15% | APIs prontas? Self-serve? Automatizável? |
| Facilidade de Promoção | 15% | SEO? Orgânico? Nichos engajados? |
| Concorrência BR / Mar Azul | 15% | Já existe no Brasil? É bom? |
| Dor Real/Latente BR | 15% | Resolve problema genuíno? |
| Inovação | 10% | Disruptivo ou cópia? |
| Potencial de Receita | 10% | TAM no BR, B2B/B2C, pricing |
| Complexidade Técnica | 10% | Viável com IA? APIs disponíveis? |
| Custo de Manutenção | 5% | Infra estimada, APIs pagas |
| Aderência Cultural BR | 5% | Idioma, pagamentos, comportamento |

## Filtros Eliminatórios

Produtos são descartados automaticamente se:
- Score Solo Founder < 40
- Mar Vermelho confirmado (3+ concorrentes fortes no BR)
- Promoção 100% dependente de paid media
- Custo infra estimado > $200/mês para começar
- Precisa de licença/regulação (saúde, financeiro, jurídico)

## Requisitos

- `curl` - Para scraping e API calls
- `jq` - Para parsing de JSON
- `grep`, `sed`, `awk` - Para parsing de HTML/texto
- Variáveis de ambiente (veja seção Configuração)

## Configuração

### Variáveis de Ambiente

O script aceita duas opções de configuração:

**Opção 1: Variáveis específicas do Radar (recomendado)**

| Variável | Descrição |
|----------|-------------|
| `RADAR_TELEGRAM_BOT_TOKEN` | Token do bot Telegram do @BotFather |
| `RADAR_TELEGRAM_CHAT_ID` | Chat ID para receber relatórios |

**Opção 2: Variáveis globais (fallback)**

| Variável | Descrição |
|----------|-------------|
| `TELEGRAM_BOT_TOKEN` | Token do bot Telegram global |
| `TELEGRAM_CHAT_ID` | Chat ID global para notificações |

### Configuração via GitHub Secrets

Para que as variáveis estejam disponíveis no container do agente, configure como GitHub Secrets com o prefixo `AGENT_LLM_`:

```
AGENT_LLM_RADAR_TELEGRAM_BOT_TOKEN=seu-bot-token
AGENT_LLM_RADAR_TELEGRAM_CHAT_ID=seu-chat-id
```

Ou use as variáveis globais:

```
AGENT_LLM_TELEGRAM_BOT_TOKEN=seu-bot-token
AGENT_LLM_TELEGRAM_CHAT_ID=seu-chat-id
```

### Como Descobrir seu Chat ID

1. **Abra o Telegram** e inicie uma conversa com seu bot
2. **Use @userinfobot** - envie `/start` e ele retornará seu ID
3. **Ou acesse a API**: `https://api.telegram.org/bot<TOKEN>/getUpdates`
4. **Procure por**: `"chat":{"id":SEU_CHAT_ID`

### Cron Job

Configurado em `config/CRONS.json`:

```json
{
  "name": "ai-opportunity-radar",
  "schedule": "0 9 * * 1,5",
  "enabled": true,
  "type": "command",
  "command": "bash /app/skills/ai-opportunity-radar/radar.sh"
}
```

Executa às 9h nas segundas e sextas-feiras.

## Diagnóstico e Testes

### Verificar Configuração

```bash
# Diagnóstico completo
skills/ai-opportunity-radar/diagnose.sh

# Testar conexão Telegram
skills/ai-opportunity-radar/test-telegram.sh

# Descobrir chat_id
skills/ai-opportunity-radar/find-chat-id.sh
```

### Problemas Comuns

**Erro: "chat not found"**

Causa: O bot não pode enviar mensagens para o chat_id fornecido.

Solução:
1. Abra o Telegram e procure pelo seu bot
2. Clique em "Start" para iniciar uma conversa
3. Descubra seu chat_id correto usando `find-chat-id.sh` ou @userinfobot
4. Atualize a variável `RADAR_TELEGRAM_CHAT_ID`

**Erro: "variável não definida"**

Causa: As variáveis de ambiente não foram configuradas.

Solução:
1. Configure os GitHub Secrets com prefixo `AGENT_LLM_`
2. Ou exporte as variáveis manualmente para testes

## Saída

Relatório formatado enviado via Telegram com:

```
🚀 RADAR DE OPORTUNIDADES IA - [DATA]

📊 RESUMO
- XX produtos analisados
- XX passaram nos filtros
- XX oportunidades mar azul

🏆 TOP 10 OPORTUNIDADES

1️⃣ [Nome] - Score: XX/100
   📌 Categoria: [categoria]
   💡 O que faz: [descrição]
   🏢 Solo Founder: XX/100 ✅
   🌊 Mar Azul: 🟢 [explicação]
   📣 Promoção: XX/100 [fácil/médio]
   💰 Potencial: [B2B/B2C, pricing]
   🛠 Complexidade: [baixa/média/alta]
   💸 Custo infra: ~$XX/mês
   
   ✨ Oportunidade BR:
   [Análise específica]
   
   🎯 Recomendação: [ação sugerida]

[... 2-10]

📉 DESCARTADOS
- [Produto]: [motivo]

🔗 Fontes: There's An AI For That, Product Hunt, Reddit, Future Tools
```

## Debug

O script gera logs em `/tmp/radar-YYYYMMDD-HHMMSS/`:
- `collect.log` - Log da coleta
- `analyze.log` - Log da análise
- `products.json` - Produtos coletados (raw)
- `analyzed.json` - Produtos analisados com scores
- `report.md` - Relatório final

## Quando Usar

- Descoberta de oportunidades de negócio em IA/SaaS
- Análise de tendências globais com foco no Brasil
- Identificação de nichos com baixa concorrência
- Validação de ideias antes de desenvolver
- Monitoramento contínuo do mercado de IA

## Fontes de Dados

1. **There's An AI For That** (theresanaiforthat.com)
   - Categorias em alta
   - Produtos novos
   - Trending

2. **Product Hunt** (producthunt.com)
   - Lançamentos de IA dos últimos 7 dias
   - Upvotes e comentários
   - Featured products

3. **Reddit** (reddit.com)
   - r/SaaS - Discussões de SaaS
   - r/artificial - Tendências de IA
   - Posts sobre dores e soluções

4. **Future Tools** (futuretools.io)
   - Ferramentas emergentes por categoria
   - Novas adições
   - Trending tools

## Notas Importantes

- Scripts usam scraping respeitoso com delays entre requests
- Rate limiting implementado para evitar bloqueios
- Dados coletados são temporários (não persistem entre execuções)
- Análise de concorrência é indicativa, não exaustiva
