# AI Opportunity Radar B2C - Guia de Configuração

## Status: ✅ FUNCIONANDO (Refatorado 2026-03-24)

O radar foi refatorado com foco TOTAL em B2C - consumidor final brasileiro.

## ⚡ Quick Start

### 1. Configurar GitHub Secrets

Acesse **Settings** → **Secrets and variables** → **Actions** e adicione:

```
AGENT_LLM_RADAR_TELEGRAM_BOT_TOKEN=seu-bot-token
AGENT_LLM_RADAR_TELEGRAM_CHAT_ID=seu-chat-id
```

### 2. Executar o Radar

```bash
bash skills/ai-opportunity-radar/radar.sh
```

## 🎯 O Que Mudou (Refatoração B2C)

### Antes (Generalista)
- Qualquer tipo de produto IA
- Scoring genérico
- Fontes variadas

### Depois (B2C Focused)
- **APENAS** produtos para consumidor final
- **EXCLUI**: infra, B2B enterprise, DevTools
- **FOCO**: dores do brasileiro, fácil implementação
- **CRITÉRIO**: 1 pessoa, 1-4 semanas, <$30/mês

## Novos Critérios de Scoring

| Critério | Peso | Pergunta |
|----------|------|----------|
| Dor do brasileiro | 25% | Brasileiro TEM esse problema? |
| Facilidade de implementação | 25% | 1 pessoa em 1-4 semanas? |
| Custo de manutenção | 15% | <$30/mês total? |
| Facilidade de promoção | 15% | Orgânico no TikTok/Instagram? |
| Concorrência BR | 10% | Não existe ou é ruim? |
| Monetização B2C | 10% | R$19-49/mês ou R$29-99 único? |

## Novas Fontes B2C

| Fonte | O que coleta |
|-------|--------------|
| **Consumer Tools** | There's An AI For That (categorias consumer) |
| **Product Hunt B2C** | Lançamentos AI + Consumer (não DevTools) |
| **Reddit Pain Points** | Dores reais de usuários |
| **Social Trends** | Ferramentas viralizando no TikTok/Instagram |

## Estrutura de Arquivos

```
skills/ai-opportunity-radar/
├── SKILL.md              # Documentação principal
├── SETUP.md              # Este arquivo
├── radar.sh              # Script principal
├── analyze-b2c.sh        # Análise B2C-focused
├── telegram.sh           # Envio via Telegram
├── diagnose.sh           # Diagnóstico
├── test-telegram.sh      # Teste conexão
└── sources/
    ├── consumer-tools.sh     # There's An AI For That (B2C)
    ├── producthunt-b2c.sh    # Product Hunt (consumer filter)
    ├── reddit-painpoints.sh  # Reddit dores reais
    └── social-trends.sh      # TikTok/social trends
```

## O Que É Excluído Automaticamente

| Tipo | Motivo |
|------|--------|
| Infraestrutura/DevTools | Não é B2C |
| B2B Enterprise | Precisa de vendas consultivas |
| Compete com Big Tech | Google/Microsoft/OpenAI/Meta |
| Precisa de suporte | Não é self-service |
| Custo > $50/mês | Inviável para solo founder |
| Setor regulado | Saúde, financeiro, jurídico |

## Formato do Relatório

```
🚀 RADAR OPORTUNIDADES B2C BRASIL - [DATA]

📊 RESUMO
• XX produtos analisados
• XX focados em consumidor final (B2C)
• XX implementáveis em < 4 semanas
• XX com custo < $30/mês

🏆 TOP 10 OPORTUNIDADES B2C

1️⃣ [Nome]
   😰 Dor: [dor específica]
   👥 Público: [público-alvo]
   🛠 Tempo: [1-2 semanas]
   💸 Custo: ~$XX/mês
   📱 Promoção: [canal]
   💰 Preço: R$XX/mês
   🌊 Concorrência: 🟢/🟡/🔴
   
   ✨ Por que funciona no BR
   🎯 MVP em 2 semanas

📉 DESCARTADOS (e por quê)
💡 COMEÇAR POR AQUI
📱 CANAIS DE PROMOÇÃO ORGÂNICA
```

## Troubleshooting

### Erro: "chat not found"
Abra o Telegram e inicie conversa com seu bot.

### Erro: "BOT_TOKEN not set"
Verifique se os secrets têm prefixo `AGENT_LLM_`.

### Produtos não aparecem
Verifique se não estão sendo filtrados como não-B2C.

## Comandos Úteis

```bash
# Executar radar completo
bash skills/ai-opportunity-radar/radar.sh

# Apenas coletar dados
bash skills/ai-opportunity-radar/radar.sh --collect-only

# Analisar arquivo específico
bash skills/ai-opportunity-radar/radar.sh --input /path/to/products.json

# Apenas enviar relatório
bash skills/ai-opportunity-radar/radar.sh --send-only /path/to/report.md

# Diagnóstico
bash skills/ai-opportunity-radar/diagnose.sh

# Testar Telegram
bash skills/ai-opportunity-radar/test-telegram.sh
```

## Cron Job

Configurado em `config/CRONS.json`:

```json
{
  "name": "ai-opportunity-radar-b2c",
  "schedule": "0 9 * * 1,5",
  "enabled": true,
  "type": "command",
  "command": "bash /app/skills/ai-opportunity-radar/radar.sh"
}
```

Executa às 9h nas segundas e sextas-feiras.

---

**Última atualização**: 2026-03-24
**Status**: ✅ Funcionando - Foco total em B2C
