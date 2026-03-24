---
name: ai-opportunity-radar
description: Radar automatizado de oportunidades B2C de IA/SaaS para o consumidor brasileiro. Foco total em produtos simples que resolvem dores do dia a dia.
---

# AI Opportunity Radar - B2C Brasil

Radar automatizado que encontra produtos de IA para **consumidor final brasileiro** (B2C), focando em:
- Dores REAIS do dia a dia
- Fácil implementação (1 pessoa, 1-4 semanas)
- Custo baixo (< $30/mês)
- Promoção orgânica (sem time de vendas)
- Self-service (zero suporte)

## ⚡ Quick Start

**Status**: ✅ Funcionando (refatorado 2026-03-24)

1. **Configure os GitHub Secrets** (obrigatório):
   ```
   AGENT_LLM_RADAR_TELEGRAM_BOT_TOKEN=seu-bot-token
   AGENT_LLM_RADAR_TELEGRAM_CHAT_ID=seu-chat-id
   ```

2. **Execute o radar**:
   ```bash
   bash skills/ai-opportunity-radar/radar.sh
   ```

## 🎯 O Que Procuramos

### ✅ INCLUDE (B2C Consumer)

| Categoria | Exemplos | Por que funciona |
|-----------|----------|------------------|
| **Geradores de conteúdo social** | Legendas Instagram, posts LinkedIn, scripts TikTok | Todo mundo quer se destacar nas redes |
| **Assistentes pessoais** | Organizar vida, planejar semana, lembretes inteligentes | Brasileiro é desorganizado por natureza |
| **Ferramentas para criadores** | Thumbnails, cortes de vídeo, cronograma de posts | Creator economy explodindo no BR |
| **Geradores de documentos simples** | Contratos básicos, currículos, textos formais | Burocracia assusta, facilitadores vendem |
| **Bots WhatsApp/Telegram** | Auto-resposta, agendamento, lembretes | WhatsApp é onipresente no BR |
| **Ferramentas de estudo** | Resumos, flashcards, explicações | Estudantes sobrecarregados |
| **Tradutores/ressumidores** | PDFs, artigos, vídeos em inglês | Brasileiro tem dificuldade com inglês |
| **Geradores de imagens/vídeos** | Avatares, cartões, convites | Resultado visual = viral |
| **Planejadores pessoais** | Viagem, dieta, exercício, finanças | Brasileiro quer melhorar mas não sabe como |
| **Geradores de nomes/ideias** | Nomes de bebê, nomes de negócio, presentes | Criatividade não é dom de todos |

### ❌ EXCLUDE (Não B2C)

| Excluir | Motivo |
|---------|--------|
| **Infraestrutura/DevTools** | APIs, frameworks, hosting, databases |
| **B2B Enterprise** | Vendas consultivas, contratos longos |
| **Compete com Big Tech** | Google, Microsoft, OpenAI, Meta |
| **Precisa de vendas/suporte** | Não é self-service |
| **Custo > $50/mês** | Inviável para solo founder iniciante |
| **Precisa de dados massivos** | Barreira de entrada alta |
| **Setor regulado** | Saúde, financeiro, jurídico sério |
| **Enterprise productivity** | Notion clone, Slack clone, etc. |

## Uso

```bash
# Executar radar completo
skills/ai-opportunity-radar/radar.sh

# Apenas coletar dados
skills/ai-opportunity-radar/radar.sh --collect-only

# Apenas analisar dados existentes
skills/ai-opportunity-radar/radar.sh --analyze-only

# Analisar arquivo específico
skills/ai-opportunity-radar/radar.sh --input /path/to/products.json

# Apenas enviar relatório
skills/ai-opportunity-radar/radar.sh --send-only /path/to/report.md
```

## Estrutura

```
skills/ai-opportunity-radar/
├── SKILL.md              # Esta documentação
├── radar.sh              # Script principal
├── analyze-b2c.sh        # Análise B2C-focused
├── telegram.sh           # Envio Telegram
├── diagnose.sh           # Diagnóstico
├── test-telegram.sh      # Teste conexão
└── sources/
    ├── consumer-tools.sh     # Consumer AI tools
    ├── producthunt-b2c.sh    # Product Hunt (consumer filter)
    ├── reddit-painpoints.sh  # Reddit dores reais
    └── social-trends.sh      # TikTok/social trends
```

## Critérios de Análise B2C

| Critério | Peso | Pergunta Chave |
|----------|------|----------------|
| **Dor do brasileiro** | 25% | Brasileiro comum TEM esse problema no dia a dia? |
| **Facilidade de implementação** | 25% | 1 pessoa constrói em 1-4 semanas? |
| **Custo de manutenção** | 15% | < $30/mês total (server + APIs)? |
| **Facilidade de promoção** | 15% | Orgânico no TikTok/Instagram? Boca a boca? |
| **Concorrência BR** | 10% | Não existe ou é mal executado? |
| **Monetização B2C clara** | 10% | Usuário paga R$19-49/mês ou R$29-99 único? |

## Filtros Eliminatórios B2C

Produto é DESCARTADO automaticamente se:

| Filtro | Motivo |
|--------|--------|
| `is_b2c = false` | Não é voltado para consumidor final |
| `is_infrastructure = true` | É infra/DevTool |
| `is_enterprise = true` | Precisa de vendas consultivas |
| `competes_with_big_tech = true` | Google/Microsoft/OpenAI/Meta já fazem |
| `needs_sales_team = true` | Não é self-service |
| `maintenance_cost > 50` | Custo > $50/mês para começar |
| `is_regulated = true` | Saúde, financeiro, jurídico |
| `implementation_weeks > 4` | Mais de 4 semanas para MVP |

## Análise de Viabilidade B2C

Para cada produto, o radar avalia:

### 1. Implementação
- **APIs prontas**: OpenAI, Replicate, etc.
- **Banco de dados**: Precisa? Supabase free tier basta?
- **Autenticação**: NextAuth simples ou sem auth?
- **Stack**: React/Next.js básico funciona?

### 2. Custo Mensal Estimado
```
Hosting:     Vercel/Netlify     $0-20
APIs:        OpenAI/Replicate   $10-30
Database:    Supabase           $0
Storage:     Cloudflare R2      $0-5
─────────────────────────────────────
TOTAL:                          $10-55 (aceitável: <$30)
```

### 3. Promoção Orgânica
- **TikTok**: Vídeo 30-60s mostrando resultado
- **Instagram Reels**: Antes/depois
- **Boca a boca**: Compartilhável?
- **SEO**: Busca orgânica funciona?
- **Comunidades**: Grupos Facebook/WhatsApp/Reddit

### 4. Concorrência Real no BR
- Google: "[produto] brasil", "[funcionalidade] online gratis"
- TikTok: Buscar vídeos sobre o tema
- Avaliar: Existe? É bom? É caro? É em inglês?

## Formato do Relatório

```
🚀 RADAR OPORTUNIDADES B2C BRASIL - [DATA]

📊 RESUMO
• XX produtos analisados
• XX focados em consumidor final (B2C)
• XX implementáveis em < 4 semanas
• XX com custo < $30/mês

🏆 TOP 10 OPORTUNIDADES B2C

1️⃣ [Nome da ideia/produto]
   😰 Dor: [dor específica do brasileiro - 1 frase]
   👥 Público: [ex: "Estudantes universitários"]
   🛠 Tempo: [1-2 semanas / 3-4 semanas]
   💸 Custo: ~$XX/mês
   📱 Promoção: [TikTok / Instagram / Boca a boca / SEO]
   💰 Preço: R$XX/mês ou R$XX único
   🌊 Concorrência: [🟢 Nenhuma / 🟡 Ruim / 🔴 Saturado]
   
   ✨ Por que funciona no BR:
   [2 frases sobre aderência cultural, timing, oportunidade]
   
   🎯 MVP em 2 semanas:
   [Feature mínima viável]

2️⃣ ...

📉 DESCARTADOS (e por quê)
• [Produto]: B2B complexo, precisa de vendas
• [Produto]: Infraestrutura cara, > $100/mês

💡 COMEÇAR POR AQUI:
1. [Top 1] - [motivo: mais fácil + maior dor]
2. [Top 2] - [motivo: segundo mais promissor]

📱 CANAIS DE PROMOÇÃO ORGÂNICA:
• TikTok: tutoriais 30-60s
• Instagram Reels: antes/depois
• Grupos Facebook/WhatsApp
• Reddit BR / Tabnews
• Product Hunt Brasil

🔗 Fontes: [lista de fontes]
```

## Exemplos de Oportunidades B2C

| Ideia | Dor | Tempo | Custo | Promoção |
|-------|-----|-------|-------|----------|
| Gerador de legendas Instagram | Social media perde tempo | 1-2 sem | $20/mês | TikTok viral |
| Resumidor de PDFs para estudo | Estudantes sobrecarregados | 1 sem | $15/mês | Grupos faculdade |
| Gerador de posts LinkedIn | Profissional quer se destacar | 2 sem | $20/mês | LinkedIn orgânico |
| Bot WhatsApp pequeno comércio | Comércio não atende 24h | 2-3 sem | $10/mês | Boca a boca |
| Gerador de scripts TikTok | Criador não sabe o que falar | 1 sem | $15/mês | TikTok itself |
| Planejador de dieta simples | Brasileiro quer emagrecer | 2 sem | $20/mês | Influencers fitness |
| Gerador de currículo otimizado | Desempregado precisa de CV | 1 sem | $10/mês | Grupos emprego |
| Criador de cardápio digital | Restaurante quer cardápio bonito | 1 sem | $5/mês | Indicação donos |

## Configuração

### Variáveis de Ambiente

| Variável | Descrição |
|----------|-----------|
| `RADAR_TELEGRAM_BOT_TOKEN` | Token do bot Telegram |
| `RADAR_TELEGRAM_CHAT_ID` | Chat ID para relatórios |

### GitHub Secrets

Configure com prefixo `AGENT_LLM_`:

```
AGENT_LLM_RADAR_TELEGRAM_BOT_TOKEN=seu-token
AGENT_LLM_RADAR_TELEGRAM_CHAT_ID=seu-chat-id
```

### Cron Job

```json
{
  "name": "ai-opportunity-radar-b2c",
  "schedule": "0 9 * * 1,5",
  "enabled": true,
  "type": "command",
  "command": "bash /app/skills/ai-opportunity-radar/radar.sh"
}
```

## Diagnóstico

```bash
# Verificar configuração
skills/ai-opportunity-radar/diagnose.sh

# Testar Telegram
skills/ai-opportunity-radar/test-telegram.sh
```

## Debug

Logs salvos em `/tmp/radar-YYYYMMDD-HHMMSS/`:
- `collect.log` - Log da coleta
- `analyze.log` - Log da análise
- `products.json` - Produtos coletados
- `analyzed.json` - Produtos analisados
- `report.md` - Relatório final

## Quando Usar

- Descoberta de produtos B2C em IA
- Validação de ideias antes de desenvolver
- Identificação de nichos com baixa concorrência no BR
- Monitoramento de tendências consumer

## Fontes de Dados

1. **There's An AI For That** - Categorias consumer
2. **Product Hunt** - AI + Consumer (não DevTools)
3. **Reddit** - Dores reais de usuários
4. **TikTok Trends** - Ferramentas viralizando
