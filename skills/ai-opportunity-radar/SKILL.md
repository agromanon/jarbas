---
name: ai-opportunity-radar
description: Radar automatizado de oportunidades de IA/SaaS para o mercado brasileiro. Coleta produtos de múltiplas fontes, analisa viabilidade e envia relatório via Telegram.
---

# AI Opportunity Radar

Radar automatizado que monitora tendências globais de IA/SaaS e identifica oportunidades específicas para o mercado brasileiro.

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
- Variáveis de ambiente:
  - `RADAR_TELEGRAM_BOT_TOKEN` - Token do bot Telegram
  - `RADAR_TELEGRAM_CHAT_ID` - Chat ID de destino

## Configuração

### Passo 1: Criar Bot no Telegram

1. Abra o Telegram e procure por @BotFather
2. Envie `/newbot` e siga as instruções
3. Salve o token fornecido (ex: `123456789:ABCdefGHI...`)

### Passo 2: Obter Chat ID

⚠️ **IMPORTANTE:** O bot só pode enviar mensagens para chats que iniciaram conversa com ele.

1. Abra o Telegram
2. Procure pelo seu bot (ex: @Radariabr_bot)
3. Envie qualquer mensagem (ex: `/start`)
4. Execute o script de verificação:
   ```bash
   bash /tmp/radar-check-and-send.sh
   ```
5. O script vai capturar seu Chat ID automaticamente

### Passo 3: Configurar Secrets no GitHub

Adicione em **Settings > Secrets and variables > Actions**:

| Secret Name | Valor |
|-------------|-------|
| `AGENT_LLM_RADAR_TELEGRAM_BOT_TOKEN` | Token do bot |
| `AGENT_LLM_RADAR_TELEGRAM_CHAT_ID` | Chat ID capturado |

### Variáveis de Ambiente

| Variável | Descrição | Obrigatório |
|----------|-------------|-------------|
| `RADAR_TELEGRAM_BOT_TOKEN` | Token do bot Telegram do @BotFather | Sim |
| `RADAR_TELEGRAM_CHAT_ID` | Chat ID para receber relatórios | Sim |

**Nota:** No thepopebot, use o prefixo `AGENT_LLM_` para secrets acessíveis ao LLM.

### Cron Job

Adicionar em `config/CRONS.json`:

```json
{
  "name": "ai-opportunity-radar",
  "schedule": "0 9 * * 1,5",
  "enabled": true,
  "type": "command",
  "command": "skills/ai-opportunity-radar/radar.sh"
}
```

Executa às 9h nas segundas e sextas-feiras.

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
