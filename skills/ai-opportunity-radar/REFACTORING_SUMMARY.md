# AI Opportunity Radar - B2C Refactoring Summary

## 📅 Date
2026-03-24

## 🎯 Objective
Refactor the `ai-opportunity-radar` skill to focus exclusively on B2C (consumer) products for the Brazilian market, filtering out infrastructure, enterprise, and regulated products.

## ✅ What Was Changed

### 1. **analyze.sh** - Complete Scoring System Overhaul

#### New Scoring Criteria (B2C Focused)
| Criterion | Weight | What It Evaluates |
|-----------|--------|-------------------|
| **Dor do Brasileiro** | 20% | Real pain points for Brazilian consumers |
| **Facilidade de Implementação** | 20% | Can it be built in 1-4 weeks by solo founder? |
| **Custo de Manutenção** | 15% | < $30/month infrastructure cost |
| **Facilidade de Promoção** | 15% | Organic promotion via TikTok/Instagram |
| **Concorrência BR** | 15% | Blue ocean or weak competitors in Brazil |
| **Monetização Clara** | 10% | Clear $5-29/month or one-time payment model |
| **Zero Suporte/Vendas** | 5% | 100% self-service product |

#### New Filters (Eliminatory)
Products are automatically **discarded** if they match ANY of these criteria:

- ❌ **Infrastructure/Dev Tools**: APIs, SDKs, frameworks, hosting, deployment platforms
- ❌ **B2B/Enterprise**: Corporate solutions, sales team required, consulting
- ❌ **Regulated Sectors**: Medical, financial, legal, healthcare, investment
- ❌ **Big Tech Competitors**: Products competing with Google, Microsoft, OpenAI, etc.
- ❌ **Red Ocean**: Strong competition confirmed in Brazil
- ❌ **Low Pain Score**: < 35/100 on Brazilian pain points
- ❌ **High Complexity**: Implementation score < 40/100
- ❌ **High Cost**: Infrastructure cost > $50/month
- ❌ **High Support**: Requires intensive sales/support (not self-service)

### 2. **radar.sh** - Enhanced Report Format

#### New Report Sections
- **📊 RESUMO**: Total analyzed, B2C-focused, quick wins (< 4 weeks), blue ocean opportunities
- **🏆 TOP 10 OPORTUNIDADES B2C**: Each product with:
  - 💡 Product description
  - 😰 Pain point solved
  - 👥 Target audience
  - 🛠 Implementation time
  - 💸 Infrastructure cost
  - 📱 Promotion strategy
  - 💰 Revenue model
  - 🌊 Competition status (🟢 Green / 🟡 Yellow / 🔴 Red)
  - 🏢 Solo founder viability
  - ⭐ Final score (0-100)
  - ✨ Why it works in Brazil
  - 🎯 Concrete next steps
- **📉 DESCARTADOS E POR QUÊ**: Discarded products with clear reasons
- **💰 IDEIAS DE MONETIZAÇÃO B2C**: Pricing strategies for consumer products
- **📱 CANAIS DE PROMOÇÃO ORGÂNICA**: TikTok, Instagram, Facebook groups, forums

### 3. **SKILL.md** - Updated Documentation

- Clarified B2C focus throughout
- Added examples of ideal B2C opportunities
- Listed excluded categories (infrastructure, B2B, regulated)
- Updated scoring criteria table
- Added filter explanations
- Improved usage examples

## 🧪 Test Results

### Test Dataset
- **20 products** from various sources
- **11 passed** B2C filters (55%)
- **9 discarded** (45%)

### Products That Passed (Examples)
✅ Instagram Caption Generator (81/100) - Criadores de conteúdo BR
✅ TikTok Script Generator (81/100) - Criadores de conteúdo BR
✅ LinkedIn Post Generator (81/100) - Profissionais BR
✅ Resume Builder BR (80/100) - Profissionais em busca de emprego
✅ Study Notes Generator (79/100) - Estudantes universitários BR
✅ WhatsApp FAQ Bot Builder (76/100) - Pequenos comércios/autônomos

### Products That Failed (Examples)
❌ LangChain - Infrastructure/platform (not B2C)
❌ Notion AI - Competes with big tech
❌ Medical AI Diagnosis - Regulated sector
❌ Investment AI Advisor - Regulated sector
❌ Replicate - Infrastructure/platform (not B2C)
❌ Enterprise AI Platform - B2B/Enterprise (not consumer)

## 📊 Key Improvements

### Before
- Mixed B2B and B2C products
- Infrastructure and dev tools included
- Complex enterprise solutions
- Products competing with big techs
- No clear consumer focus

### After
- **100% B2C consumer focus**
- Infrastructure/dev tools automatically filtered
- Simple products for solo founders
- Blue ocean opportunities prioritized
- Clear target audiences (students, creators, small businesses, etc.)
- Organic promotion channels emphasized
- Low maintenance cost required (< $30/month)

## 🎯 Ideal B2C Product Profile

The refactored radar now prioritizes products that:

1. **Solve real Brazilian pain points**
   - Bureaucracy (CPF, CNPJ, invoices)
   - Education (study aids, summaries)
   - Content creation (social media, videos)
   - Job market (resumes, LinkedIn)
   - Small business (WhatsApp bots, menus)

2. **Easy to build**
   - 1-4 weeks for solo founder
   - APIs readily available
   - No complex ML/infrastructure
   - Simple web app or bot

3. **Easy to promote**
   - TikTok/Instagram viral potential
   - Before/after demonstrations
   - Niche communities (students, creators)
   - No sales team required

4. **Low cost to maintain**
   - <$30/month infrastructure
   - Serverless or simple hosting
   - Minimal ongoing support
   - Self-service onboarding

5. **Clear monetization**
   - Freemium R$19-29/month
   - One-time R$29-49
   - Credits/prepaid R$10-50
   - No enterprise pricing

## 🚀 Next Steps

1. **Run on real data sources**:
   - There's An AI For That (filter by consumer categories)
   - Product Hunt (filter by AI + consumer-friendly)
   - Reddit r/SaaS (user pain points)
   - TikTok Creative Center (trending AI topics)

2. **Analyze competition** for top opportunities:
   - Google BR search
   - TikTok/Instagram search
   - Product Hunt Brasil
   - Reclame Aqui (if competitors exist)

3. **Send report via Telegram** to validate format

## 📝 Files Modified

- `skills/ai-opportunity-radar/analyze.sh` - New scoring + filters
- `skills/ai-opportunity-radar/radar.sh` - Enhanced report format
- `skills/ai-opportunity-radar/SKILL.md` - Updated documentation

## 🔍 Testing Commands

```bash
# Test with sample data
bash skills/ai-opportunity-radar/analyze.sh /tmp/test-b2c-products.json /tmp/test-analyzed.json

# Generate report
bash skills/ai-opportunity-radar/radar.sh --input /tmp/test-b2c-products.json --analyze-only

# View report
cat /tmp/radar-*/report.md

# Full run (collect + analyze + send)
bash skills/ai-opportunity-radar/radar.sh
```

## ✨ Conclusion

The refactored radar is now **laser-focused on B2C opportunities** for Brazilian consumers. It automatically filters out infrastructure, enterprise, and regulated products, prioritizing simple, low-cost, easy-to-promote solutions that a solo founder can build in weeks, not months.

The scoring system rewards products that:
- Solve real Brazilian pain points
- Can be built quickly by one person
- Cost little to maintain
- Promote themselves organically
- Have clear monetization paths
- Require minimal support

This makes it much more actionable for solo founders looking to build consumer AI products for the Brazilian market.
