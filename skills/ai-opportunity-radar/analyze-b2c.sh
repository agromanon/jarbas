#!/bin/bash
#
# AI Opportunity Radar - B2C Analysis Engine
# Analisa produtos com foco TOTAL em consumidor final brasileiro
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[analyze-b2c] $1"
}

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: analyze-b2c.sh <input.json> <output.json>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

log "Analyzing B2C products from: $INPUT_FILE"

# Get total products
TOTAL=$(jq '.products | length' "$INPUT_FILE")
log "Total products to analyze: $TOTAL"

# Create output with B2C-focused scoring
log "Processing products with B2C criteria..."

# Create jq filter file
cat > /tmp/b2c-filter.jq << 'JQEOF'
# Combine text fields safely
def get_text:
  ((.description // "") + " " + (.name // "") + " " + (.category // ""));

# Check if excluded (not B2C)
def is_excluded:
  . as $p |
  get_text as $text |
  {
    is_infra: ($text | test("api gateway|framework|sdk|devtools|developer tool|infrastructure|hosting|deployment"; "i")),
    is_enterprise: (($text | test("enterprise|b2b|crm|erp|consulting|contract|for businesses"; "i")) and ($text | test("small business|freelancer|individual|personal"; "i") | not)),
    competes_big_tech: ($text | test("alternative to (google|chatgpt|notion|slack|figma|canva|microsoft|meta|openai)"; "i")),
    needs_sales: ($text | test("dedicated support|sales call|demo request|consultation|onboarding specialist"; "i")),
    is_regulated: (($text | test("medical diagnosis|prescription|financial advice|legal advice|healthcare platform"; "i")) and ($text | test("planner|tracker|organizer|simple|basic"; "i") | not)),
    is_enterprise_clone: ($text | test("slack alternative|notion alternative|project management for teams|team collaboration"; "i"))
  } | . + {excluded: (.is_infra or .is_enterprise or .competes_big_tech or .needs_sales or .is_regulated or .is_enterprise_clone)};

# Calculate B2C scores
def calculate_b2c_scores:
  . as $p |
  get_text as $text |
  {
    pain_brazilian: (
      if $text | test("instagram|tiktok|social media|whatsapp|linkedin"; "i") then 90
      elif $text | test("study|student|homework|exam|learning|estud"; "i") then 85
      elif $text | test("resume|cv|job|curriculo|empreg"; "i") then 85
      elif $text | test("diet|weight loss|fitness|exercise|emagrec|dieta"; "i") then 80
      elif $text | test("translate|summarize|pdf|article|traduz|resum"; "i") then 80
      elif $text | test("plan|organize|schedule|calendar|planej|organiz"; "i") then 75
      elif $text | test("content|creator|thumbnail|video edit|conteudo"; "i") then 85
      elif $text | test("gift|present|name generator|baby|nome|presente"; "i") then 70
      elif $text | test("small business|freelancer|autonomo|pme"; "i") then 70
      elif $text | test("writing|caption|post|text|escrev|legenda"; "i") then 75
      elif $text | test("invoice|receipt|budget|finance|nota fiscal"; "i") then 65
      elif $text | test("enterprise|b2b|corporate|business solution"; "i") then 20
      elif $text | test("api|framework|sdk|developer|infrastructure"; "i") then 10
      else 50
      end
    ),
    implementation_ease: (
      if $text | test("api wrapper|browser extension|simple|basic|mini|mvp"; "i") then 95
      elif $text | test("generator|creator|maker|builder|wizard"; "i") then 85
      elif $text | test("chatbot|assistant|bot|automation"; "i") then 80
      elif $text | test("template|preset|one-click|instant"; "i") then 90
      elif $text | test("translation|summarizer|converter"; "i") then 80
      elif $text | test("planner|tracker|organizer"; "i") then 75
      elif $text | test("image generation|video|real-time|streaming"; "i") then 50
      elif $text | test("mobile app|native|hardware|robot"; "i") then 25
      elif $text | test("enterprise|platform|ecosystem|marketplace"; "i") then 20
      else 60
      end
    ),
    maintenance_cost: (
      if $text | test("static|client-side|browser extension|no backend"; "i") then 95
      elif $text | test("simple|basic|mini|lightweight"; "i") then 85
      elif $text | test("api wrapper|integration|connector"; "i") then 80
      elif $text | test("generator|converter|transformer"; "i") then 75
      elif $text | test("chat|assistant|bot"; "i") then 70
      elif $text | test("video processing|image processing|real-time"; "i") then 40
      elif $text | test("training|fine-tuning|custom model"; "i") then 20
      elif $text | test("enterprise|scalable|distributed"; "i") then 15
      else 65
      end
    ),
    promotion_ease: (
      if $text | test("tiktok|instagram|viral|shareable|social"; "i") then 95
      elif $text | test("image|video|visual|thumbnail|design"; "i") then 85
      elif $text | test("content|creator|influencer"; "i") then 85
      elif $text | test("before after|transform|result"; "i") then 80
      elif $text | test("student|study|school|college"; "i") then 75
      elif $text | test("gift|present|personal|fun"; "i") then 70
      elif $text | test("resume|job|career|professional"; "i") then 65
      elif $text | test("enterprise|b2b|business|corporate"; "i") then 30
      elif $text | test("developer|api|technical|infrastructure"; "i") then 20
      else 55
      end
    ),
    br_competition: (
      if $text | test("brazil|brasil|portuguese|pt-br|latam"; "i") then 85
      elif $text | test("local|regional|specific niche"; "i") then 75
      elif (.category // "") | test("new|emerging|trending"; "i") then 70
      elif $text | test("instagram|tiktok|social media"; "i") then 40
      elif $text | test("chatgpt|notion|canva|figma"; "i") then 15
      elif $text | test("resume|cv generator"; "i") then 35
      elif $text | test("content generator|writing"; "i") then 30
      else 50
      end
    ),
    b2c_monetization: (
      if $text | test("premium|pro|subscription|monthly|assinatura"; "i") then 80
      elif $text | test("one-time|lifetime|purchase|buy"; "i") then 75
      elif $text | test("freemium|free tier|basic plan"; "i") then 70
      elif $text | test("personal|individual|single user"; "i") then 75
      elif $text | test("enterprise|team|business plan|volume"; "i") then 25
      elif $text | test("free|open source|gratuito"; "i") then 40
      else 60
      end
    )
  };

# Helper functions
def implementation_weeks:
  if . >= 80 then "1-2 semanas"
  elif . >= 60 then "2-3 semanas"
  elif . >= 40 then "3-4 semanas"
  else "> 4 semanas"
  end;

def estimated_cost:
  if . >= 80 then "~$15/mês"
  elif . >= 60 then "~$25/mês"
  elif . >= 40 then "~$40/mês"
  else "> $50/mês"
  end;

def competition_status:
  if . >= 70 then {emoji: "🟢", text: "Nenhuma/pouca"}
  elif . >= 40 then {emoji: "🟡", text: "Existe mas fraca"}
  else {emoji: "🔴", text: "Saturado"}
  end;

def promotion_channel:
  . as $s |
  if ($s.pain_brazilian >= 80 and $s.promotion_ease >= 80) then "TikTok + Instagram"
  elif ($s.promotion_ease >= 70) then "TikTok viral"
  elif ($s.pain_brazilian >= 70) then "Grupos WhatsApp/Facebook"
  elif ($s.b2c_monetization >= 70) then "SEO + Boca a boca"
  else "Difícil"
  end;

def suggested_price:
  . as $s |
  if ($s.implementation_ease >= 80 and $s.maintenance_cost >= 80) then "R$19-29/mês ou R$49 único"
  elif ($s.implementation_ease >= 60) then "R$29-39/mês ou R$79 único"
  else "R$39-49/mês ou R$99 único"
  end;

def target_audience:
  if test("student|study|homework|exam"; "i") then "Estudantes universitários/escolares"
  elif test("instagram|tiktok|content|creator"; "i") then "Criadores de conteúdo iniciantes"
  elif test("resume|cv|job|career"; "i") then "Profissionais em busca de emprego"
  elif test("diet|fitness|exercise|weight"; "i") then "Pessoas querendo emagrecer/melhorar forma"
  elif test("small business|freelancer|autonomo"; "i") then "Pequenos comerciantes e freelancers"
  elif test("plan|organize|schedule"; "i") then "Pessoas desorganizadas (todos nós)"
  elif test("gift|present|name|baby"; "i") then "Presentes e ocasiões especiais"
  elif test("translate|summarize|pdf"; "i") then "Estudantes e profissionais lendo em inglês"
  elif test("whatsapp|bot|automation"; "i") then "Pequenos negócios e autônomos"
  else "Consumidor geral brasileiro"
  end;

def pain_description:
  if test("instagram|tiktok|social media"; "i") then "Perde tempo criando conteúdo para redes sociais"
  elif test("student|study|homework"; "i") then "Sobrecarregado com muito material para estudar"
  elif test("resume|cv|job"; "i") then "Precisa de currículo profissional mas não sabe fazer"
  elif test("diet|fitness|weight"; "i") then "Quer emagrecer mas não sabe por onde começar"
  elif test("translate|summarize"; "i") then "Tem dificuldade com textos em inglês"
  elif test("plan|organize"; "i") then "Desorganizado, esquece compromissos e tarefas"
  elif test("content|creator|thumbnail"; "i") then "Criador iniciante não sabe editar/thumbnail"
  elif test("whatsapp|bot"; "i") then "Pequeno comércio não consegue atender 24h"
  elif test("gift|present|name"; "i") then "Não tem criatividade para presentes/nomes"
  else "Problema comum do dia a dia"
  end;

def mvp_description:
  if test("instagram|caption|post"; "i") then "Página única: upload foto → gera 3 opções de legenda"
  elif test("student|study|summarize|pdf"; "i") then "Upload PDF → resumo em tópicos + flashcards"
  elif test("resume|cv"; "i") then "Formulário simples → currículo formatado em PDF"
  elif test("diet|fitness|meal"; "i") then "Input peso/altura/objetivo → plano de 7 dias"
  elif test("translate|summarize"; "i") then "Cola texto/url → traduz + resume em português"
  elif test("plan|organize|schedule"; "i") then "Input compromissos → sugestão de organização"
  elif test("content|creator|script"; "i") then "Input nicho → 10 ideias de conteúdo + scripts"
  elif test("whatsapp|bot"; "i") then "Bot básico: FAQ + horário funcionamento + cardápio"
  elif test("gift|present|name"; "i") then "Input ocasião/idade/orçamento → 5 sugestões"
  else "Página única com input → output via API"
  end;

def why_works_br:
  "Brasileiro tem essa dor no dia a dia. " +
  (if . >= 60 then "Pouca ou nenhuma solução boa em português. " else "Mercado existe, precisa de execução melhor. " end) +
  "Timing perfeito com crescimento de IA acessível.";

def exclusion_reason:
  if .is_infra then "Infraestrutura/DevTool - não é B2C"
  elif .is_enterprise then "B2B Enterprise - precisa de vendas consultivas"
  elif .competes_big_tech then "Concorre com Google/Microsoft/OpenAI/Meta"
  elif .needs_sales then "Precisa de time de vendas/suporte"
  elif .is_regulated then "Setor regulamentado (saúde/financeiro/jurídico)"
  elif .is_enterprise_clone then "Clone de ferramenta enterprise"
  else "Não passou nos critérios B2C"
  end;

def final_b2c_score:
  . as $s |
  (($s.pain_brazilian * 25) +
   ($s.implementation_ease * 25) +
   ($s.maintenance_cost * 15) +
   ($s.promotion_ease * 15) +
   ($s.br_competition * 10) +
   ($s.b2c_monetization * 10)) / 100 | floor;

# Main processing
.products | map(
  . as $product |
  ($product | is_excluded) as $exclusion |
  ($product | calculate_b2c_scores) as $scores |
  ($scores | final_b2c_score) as $final_score |
  ($product | get_text) as $full_text |
  
  {
    name: ($product.name // ""),
    description: ($product.description // ""),
    category: ($product.category // "general"),
    source: ($product.source // "unknown"),
    url: ($product.url // ""),
    scores: $scores,
    final_score: $final_score,
    is_b2c: ($exclusion.excluded | not),
    exclusion: $exclusion,
    pain_description: ($full_text | pain_description),
    target_audience: ($full_text | target_audience),
    implementation_time: ($scores.implementation_ease | implementation_weeks),
    estimated_cost: ($scores.maintenance_cost | estimated_cost),
    competition: ($scores.br_competition | competition_status),
    promotion_channel: ($scores | promotion_channel),
    suggested_price: ($scores | suggested_price),
    mvp_description: ($full_text | mvp_description),
    why_works_br: ($scores.br_competition | why_works_br),
    passed_filters: (
      ($exclusion.excluded | not) and
      $final_score >= 40 and
      $scores.implementation_ease >= 40 and
      $scores.maintenance_cost >= 40
    ),
    discard_reason: (if $exclusion.excluded then ($exclusion | exclusion_reason) else "" end)
  }
) | sort_by(.final_score) | reverse
JQEOF

# Run analysis
jq -f /tmp/b2c-filter.jq "$INPUT_FILE" > /tmp/analyzed-b2c-products.json

# Create final output with timestamp
jq --arg ts "$(date -Iseconds)" '{
    products: .,
    timestamp: $ts,
    analysis_type: "b2c_focused"
}' /tmp/analyzed-b2c-products.json > "$OUTPUT_FILE"

# Stats
PASSED=$(jq '[.products[] | select(.passed_filters == true)] | length' "$OUTPUT_FILE")
B2C=$(jq '[.products[] | select(.is_b2c == true)] | length' "$OUTPUT_FILE")
EXCLUDED=$(jq '[.products[] | select(.exclusion.excluded == true)] | length' "$OUTPUT_FILE")
CHEAP=$(jq '[.products[] | select(.passed_filters == true and .scores.maintenance_cost >= 60)] | length' "$OUTPUT_FILE")
FAST=$(jq '[.products[] | select(.passed_filters == true and .scores.implementation_ease >= 70)] | length' "$OUTPUT_FILE")

log "Analysis complete!"
log "Total analyzed: $TOTAL"
log "B2C products: $B2C"
log "Excluded (not B2C): $EXCLUDED"
log "Passed all filters: $PASSED"
log "Implementation < 4 weeks: $FAST"
log "Cost < \$30/month: $CHEAP"
log "Output saved to: $OUTPUT_FILE"

exit 0
