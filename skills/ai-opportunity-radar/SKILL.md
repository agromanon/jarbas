---
name: ai-opportunity-radar
description: Radar automatizado de oportunidades B2C de IA para o mercado brasileiro. Foco em consumidor final, produtos simples de implementar e manter, com promoção orgânica via TikTok/Instagram.
---

# AI Opportunity Radar (B2C Focus)

Radar automatizado que monitora tendências globais de IA e identifica oportunidades **B2C** específicas para o mercado brasileiro.

## ⚡ Quick Start

**Status**: ✅ Funcionando (refatorado para B2C em 2026-03-24)

1. **Configure os GitHub Secrets** (obrigatório para uso automático):
   ```
   AGENT_LLM_RADAR_TELEGRAM_BOT_TOKEN=seu-bot-token
   AGENT_LLM_RADAR_TELEGRAM_CHAT_ID=seu-chat-id
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

## 🎯 Foco B2C

Este radar foi otimizado para encontrar oportunidades de **consumidor final** (B2C), não B2B enterprise.

### O que PROCURAMOS:

✅ **Geradores de conteúdo** (posts, legendas, textos)
✅ **Assistentes pessoais simples**
✅ **Ferramentas de produtividade**
✅ **Geradores de documentos/contratos simples**
✅ **Bots para WhatsApp/Telegram**
✅ **Ferramentas para criadores de conteúdo**
✅ **Soluções para pequenos comércios** (autoatendimento)
✅ **Tradutores/ressumidores** adaptados para BR
✅ **Ferramentas de estudo/aprendizado**
✅ **Geradores de imagens/vídeos simples**

### O que EXCLUÍMOS:

❌ Infraestrutura/plataformas de dev (APIs, frameworks, hosting)
❌ Produtos enterprise/B2B complexos
❌ Coisas que competem com Google, Microsoft, OpenAI
❌ Produtos que precisam de equipe de vendas/suporte
❌ Produtos com custo de manutenção > $50/mês
❌ Produtos que precisam de dados proprietários massivos
❌ Produtos regulados (saúde, financeiro, jurídico)

## Funcionalidades

- **Coleta multi-fonte**: There's An AI For That, Product Hunt, Reddit, Future Tools
- **Filtro B2C rigoroso**: Remove automaticamente infraestrutura e B2B
- **Análise ponderada**: 7 critérios focados em consumidor final brasileiro
- **Mar Azul BR**: Identifica produtos com pouca ou nenhuma concorrência no Brasil
- **Relatório prático**: TOP 10 com próximos passos concretos

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
├── radar.sh              # Script principal de orquestração (B2C)
├── analyze.sh            # Análise e scoring de produtos (B2C)
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

## Critérios de Análise (B2C)

| Critério | Peso | O que avaliar |
|----------|------|---------------|
| **Dor do brasileiro** | 20% | Problema real do dia a dia? Brasileiro tem essa dor? |
| **Facilidade de implementação** | 20% | Dá pra fazer em 1-4 semanas sozinho? APIs prontas? |
| **Custo de manutenção** | 15% | < $30/mês? Server barato + APIs? |
| **Facilidade de promoção** | 15% | Orgânico? TikTok/Instagram? Viral? |
| **Concorrência BR** | 15% | Mar azul ou concorrentes ruins? |
| **Monetização clara** | 10% | Usuário paga quanto? $5-29/mês? |
| **Zero suporte/vendas** | 5% | Self-service total? |

## Filtros Eliminatórios (B2C)

Produtos são descartados automaticamente se:

- ❌ **Infraestrutura/plataforma dev** (APIs, SDKs, frameworks, hosting)
- ❌ **B2B/Enterprise complexo** (precisa de vendas consultivas)
- ❌ **Compete com big techs** (Google, Microsoft, OpenAI, etc.)
- ❌ **Mar vermelho confirmado** (concorrência forte no BR)
- ❌ **Não resolve dor do brasileiro** (score < 35/100)
- ❌ **Muito complexo para solo founder** (implementação < 40/100)
- ❌ **Custo infra alto** (>$50/mês)
- ❌ **Setor regulamentado** (saúde, financeiro, jurídico)
- ❌ **Precisa de vendas/suporte intensivo** (não é self-service)

## Requisitos

- `curl` - Para scraping e API calls
- `jq` - Para parsing de JSON
- `grep`, `sed`, `awk` - Para parsing de texto
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
🚀 RADAR DE OPORTUNIDADES B2C BR - [DATA]

📊 RESUMO
• XX produtos analisados
• XX focados em B2C consumidor final
• XX com implementação < 4 semanas
• XX mar azul real no BR

🏆 TOP 10 OPORTUNIDADES B2C

1️⃣ [Nome do produto]
   💡 O que é: [1 frase clara]
   😰 Dor que resolve: [dor específica do brasileiro]
   👥 Público: [quem usa - ex: "estudantes universitários BR"]
   🛠 Implementação: [1-2 semanas / 3-4 semanas]
   💸 Custo infra: ~$XX/mês
   📱 Promoção: [como divulgar - ex: "TikTok orgânico, influencers"]
   💰 Modelo: [ex: "Freemium R$19,90/mês"]
   🌊 Concorrência BR: [🟢 Nenhuma / 🟡 Existe mas é ruim / 🔴 Saturado]
   🏢 Solo founder: ✅ Sim / ❌ Precisa de time
   ⭐ Score: XX/100
   
   ✨ Por que funciona no BR:
   [2-3 frases explicando aderência cultural, timing, oportunidade]
   
   🎯 Próximos passos:
   [Ação concreta - ex: "Criar MVP em 2 semanas, testar com 100 usuários"]

[... 2-10]

📉 DESCARTADOS E POR QUÊ
• [Produto]: [motivo - ex: "B2B complexo", "Infra cara", "Concorre com Google"]

💰 IDEIAS DE MONETIZAÇÃO
• Freemium básico gratuito + premium R$19-29/mês
• One-time payment R$29-49 (lifetime access)
• Créditos pré-pagos (R$10 = 100 usos)
• Assinatura anual com desconto (2 meses grátis)

📱 CANAIS DE PROMOÇÃO ORGÂNICA
• TikTok (tutoriais, antes/depois, dicas rápidas)
• Instagram Reels (demonstrações, cases de uso)
• Grupos de Facebook/WhatsApp (nichos específicos)
• Fóruns (Reddit BR, Tabnews, Gumroad)
• Product Hunt Brasil (lançamento)
• YouTube Shorts (tutoriais em 60s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 Fontes: There's An AI For That, Product Hunt, Reddit, Future Tools
📅 Gerado em: DD/MM/YYYY às HH:MM
🎯 Foco: B2C consumidor final brasileiro
```

## Debug

O script gera logs em `/tmp/radar-YYYYMMDD-HHMMSS/`:
- `collect.log` - Log da coleta
- `analyze.log` - Log da análise
- `products.json` - Produtos coletados (raw)
- `analyzed.json` - Produtos analisados com scores
- `report.md` - Relatório final

## Quando Usar

- Descoberta de oportunidades de negócio B2C em IA
- Identificação de produtos para solo founder
- Validação de ideias antes de desenvolver
- Monitoramento de tendências com foco em consumidor final brasileiro
- Busca por produtos com baixo custo de manutenção e promoção orgânica

## Fontes de Dados

1. **There's An AI For That** (theresanaiforthat.com)
   - Categorias consumer-friendly
   - Produtos novos
   - Trending

2. **Product Hunt** (producthunt.com)
   - Lançamentos de IA dos últimos 7 dias
   - Upvotes e comentários
   - Filtro para produtos B2C

3. **Reddit** (reddit.com)
   - r/SaaS - Discussões de SaaS
   - r/artificial - Tendências de IA
   - Posts sobre dores de usuários comuns

4. **Future Tools** (futuretools.io)
   - Ferramentas emergentes por categoria
   - Novas adições
   - Trending tools

## Exemplos de Oportunidades Ideais

Para referência, oportunidades B2C que fazem sentido:

- "Gerador de legendas para Instagram com emojis e hashtags"
- "Resumidor de PDFs para estudantes universitários"
- "Gerador de posts para LinkedIn focado em profissionais BR"
- "Bot de WhatsApp que responde FAQ de pequenos comércios"
- "Gerador de contratos de aluguel simples"
- "Assistente para criar currículos otimizados para vagas BR"
- "Gerador de ideias de nomes para negócios/nomes de domínio"
- "Tradutor que adapta textos para português brasileiro informal"
- "Gerador de scripts para vídeos de TikTok/Reels"
- "Ferramenta para criar cardápios de restaurantes pequenos"

## Notas Importantes

- Scripts usam scraping respeitoso com delays entre requests
- Rate limiting implementado para evitar bloqueios
- Dados coletados são temporários (não persistem entre execuções)
- Análise de concorrência é indicativa, não exaustiva
- **Foco 100% B2C**: Infraestrutura e B2B são automaticamente filtrados
- **Solo founder friendly**: Prioriza produtos implementáveis por 1 pessoa
- **Custo baixo**: Mantém infra <$50/mês, ideal <$30/mês
- **Promoção orgânica**: Prefere produtos que viralizam no TikTok/Instagram
