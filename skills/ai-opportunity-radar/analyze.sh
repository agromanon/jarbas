#!/bin/bash
#
# AI Opportunity Radar - Analysis Engine (B2C Focus)
# Analisa produtos focando em consumidor final brasileiro
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[analyze] $1"
}

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: analyze.sh <input.json> <output.json>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

log "Analyzing products from: $INPUT_FILE (B2C Focus)"

# Get total products
TOTAL=$(jq '.products | length' "$INPUT_FILE")
log "Total products to analyze: $TOTAL"

# Create output file with jq processing all products at once
log "Processing products with B2C criteria..."

jq '
# ============================================================
# HELPER: Safe text concatenation with null handling
# ============================================================
def all_text:
    ((.description // "") + " " + (.name // "") + " " + (.category // "") + " " + (.topics // ""));

# ============================================================
# B2C SCORING FUNCTIONS - FOCO EM CONSUMIDOR FINAL BRASILEIRO
# ============================================================

def calculate_scores:
    . as $product |
    {
        # ============================================================
        # 1. DOR DO BRASILEIRO (20%) - Problema real do dia a dia?
        # ============================================================
        pain_br: (
            ($product | all_text) as $text |
            # Alta pontuação para dores específicas do brasileiro
            if $text | test("nota fiscal|imposto|cpf|cnpj|boleto|pix|burocracia|aluguel|contrato|currículo|vaga|entrevista|legenda|instagram|tiktok|reels|conteúdo|post"; "i") then 90
            # Estudantes brasileiros
            elif $text | test("pdf|resumo|estudo|prova|vestibular|enem|faculdade|universit"; "i") then 85
            # Pequenos negócios/autoatendimento
            elif $text | test("pequeno comércio|autônomo|freelancer|microempreendedor|whatsapp bot|faq|autoatendimento|menu|cardápio"; "i") then 80
            # Criadores de conteúdo
            elif $text | test("creator|influencer|youtube|tiktok|instagram|conteúdo|caption|legend"; "i") then 75
            # Produtividade pessoal
            elif $text | test("produtividade|organizar|agenda|lembrete|tarefas"; "i") then 70
            # Tradução/adaptação para BR
            elif $text | test("portuguese|português|brasil|brazil|pt-br"; "i") then 65
            # Ferramentas genéricas úteis
            elif $text | test("generator|assistant|tool|automation|gerador|assistente|ferramenta"; "i") then 50
            # Infraestrutura/dev tools - BAIXA pontuação
            elif $text | test("api|sdk|framework|library|platform|infrastructure|hosting|deployment|docker|kubernetes|cloud platform"; "i") then 15
            # Enterprise - BAIXA pontuação
            elif $text | test("enterprise|b2b|corporate|large team|sales team"; "i") then 20
            else 40
            end
        ),

        # ============================================================
        # 2. FACILIDADE DE IMPLEMENTAÇÃO (20%) - 1-4 semanas sozinho?
        # ============================================================
        implementation: (
            ($product | all_text) as $text |
            # Wrapper/API simples
            if $text | test("api wrapper|browser extension|chatbot|telegram bot|whatsapp|slack bot|discord bot"; "i") then 90
            # Geradores de texto/conteúdo
            elif $text | test("generator|writer|text|content|caption|post"; "i") then 85
            # Ferramentas simples
            elif $text | test("converter|formatter|template|simple|basic|builder|creator"; "i") then 80
            # Automações
            elif $text | test("automation|workflow|integration"; "i") then 70
            # Média complexidade
            elif $text | test("dashboard|analytics|reports|insights"; "i") then 50
            # Alta complexidade - DESFAVORÁVEL
            elif $text | test("real-time|streaming|video processing|custom ml model|training|fine-tuning"; "i") then 25
            # Infraestrutura - MUITO ALTA complexidade
            elif $text | test("platform|infrastructure|hosting|deployment|cloud"; "i") then 15
            else 60
            end
        ),

        # ============================================================
        # 3. CUSTO DE MANUTENÇÃO (15%) - < $30/mês?
        # ============================================================
        maintenance_cost: (
            ($product | all_text) as $text |
            # Muito baixo custo (serverless, estático)
            if $text | test("static|serverless|browser extension|api wrapper|webhook"; "i") then 95
            # Baixo custo (API + banco simples)
            elif $text | test("generator|chatbot|text|content|simple tool|builder"; "i") then 85
            # Médio custo (processamento leve)
            elif $text | test("automation|workflow|integration|dashboard"; "i") then 60
            # Alto custo (processamento pesado)
            elif $text | test("video|image processing|real-time|streaming|training"; "i") then 25
            # Muito alto custo (infraestrutura)
            elif $text | test("platform|infrastructure|hosting|cloud service"; "i") then 15
            else 65
            end
        ),

        # ============================================================
        # 4. FACILIDADE DE PROMOÇÃO (15%) - Orgânico? TikTok/Instagram?
        # ============================================================
        promotion: (
            ($product | all_text) as $text |
            # Muito fácil de promover organicamente
            if $text | test("tiktok|instagram|reels|youtube|social media|content|creator|influencer|viral"; "i") then 95
            # Fácil de mostrar antes/depois
            elif $text | test("generator|transformer|converter|before after|template"; "i") then 85
            # Nichos engajados (estudantes, criadores, freelancers)
            elif $text | test("student|creator|freelancer|writer|designer|estudante"; "i") then 80
            # Médio (precisa de conteúdo educativo)
            elif $text | test("productivity|automation|tool|assistant"; "i") then 65
            # Difícil (precisa de vendas B2B)
            elif $text | test("enterprise|b2b|corporate|team|business"; "i") then 30
            # Muito difícil (infraestrutura/dev tools)
            elif $text | test("api|sdk|framework|platform|infrastructure|developer tool"; "i") then 20
            else 55
            end
        ),

        # ============================================================
        # 5. CONCORRÊNCIA BR / MAR AZUL (15%) - Poucos ou ruins no BR?
        # ============================================================
        blue_ocean: (
            ($product | all_text) as $text |
            # Mar azul - nicho específico BR
            if $text | test("brazil|brasil|portuguese|pt-br|latam"; "i") then 85
            # Nicho específico com poucos players
            elif $text | test("whatsapp bot|telegram bot|nota fiscal|aluguel|contrato simples|currículo br"; "i") then 80
            # Mar amarelo - existe mas é ruim
            elif $text | test("writing|content|generator"; "i") then 45
            # Competição com big techs - MAR VERMELHO
            elif $text | test("chatgpt|notion|slack|figma|canva|google|facebook|microsoft|openai"; "i") then 10
            # Infraestrutura - já saturado
            elif $text | test("api platform|hosting|deployment|cloud|infrastructure"; "i") then 15
            else 50
            end
        ),

        # ============================================================
        # 6. MONETIZAÇÃO CLARA (10%) - $5-29/mês ou one-time?
        # ============================================================
        monetization: (
            ($product | all_text) as $text |
            # Freemium claro
            if $text | test("generator|tool|assistant|converter|builder"; "i") then 80
            # One-time payment viável
            elif $text | test("template|pack|bundle|download"; "i") then 75
            # Créditos pré-pagos
            elif $text | test("credits|pay per use|usage based"; "i") then 70
            # Subscription padrão
            elif $text | test("subscription|monthly|annual"; "i") then 60
            # Enterprise - pricing complexo
            elif $text | test("enterprise|custom pricing|contact sales"; "i") then 20
            # Free/Open source - sem monetização clara
            elif $text | test("free|open source|gratuito"; "i") then 30
            else 65
            end
        ),

        # ============================================================
        # 7. ZERO SUPORTE/VENDAS (5%) - Self-service total?
        # ============================================================
        self_service: (
            ($product | all_text) as $text |
            # 100% self-service
            if $text | test("generator|converter|template|tool|simple|automated"; "i") then 95
            # Minimal support
            elif $text | test("chatbot|assistant|automation"; "i") then 85
            # Médio - precisa de tutorial
            elif $text | test("dashboard|workflow|integration"; "i") then 60
            # Alto suporte
            elif $text | test("enterprise|custom|consulting|service"; "i") then 20
            # Infraestrutura - muito suporte
            elif $text | test("platform|infrastructure|hosting|deployment"; "i") then 25
            else 70
            end
        )
    };

# ============================================================
# DETERMINE BLUE OCEAN STATUS
# ============================================================

def blue_ocean_status:
    . as $scores |
    if $scores.blue_ocean >= 70 then "green"
    elif $scores.blue_ocean >= 40 then "yellow"
    else "red"
    end;

def blue_ocean_emoji:
    if . == "green" then "🟢"
    elif . == "yellow" then "🟡"
    else "🔴"
    end;

def blue_ocean_reason:
    . as $product |
    ($product | all_text) as $text |
    if $text | test("chatgpt|notion|slack|figma|canva|google|facebook|microsoft"; "i") then "Compete com big techs - mar vermelho"
    elif $text | test("api platform|sdk|framework|hosting|deployment|infrastructure"; "i") then "Infraestrutura saturada - não é B2C"
    elif (($product.category // "") | test("writing|content|generator"; "i")) then "Categoria com concorrência - precisa diferenciar"
    elif $text | test("brazil|brasil|portuguese|latam"; "i") then "Foco BR - mar azul real"
    elif $text | test("whatsapp bot|telegram bot|nota fiscal|aluguel|currículo"; "i") then "Nicho específico - pouca concorrência BR"
    else "Verificar concorrência no Brasil"
    end;

# ============================================================
# CALCULATE FINAL WEIGHTED SCORE (B2C FOCUSED)
# ============================================================

def final_score:
    . as $s |
    (($s.pain_br * 20) +           # Dor do brasileiro (20%)
     ($s.implementation * 20) +     # Facilidade de implementação (20%)
     ($s.maintenance_cost * 15) +   # Custo de manutenção (15%)
     ($s.promotion * 15) +          # Facilidade de promoção (15%)
     ($s.blue_ocean * 15) +         # Concorrência BR (15%)
     ($s.monetization * 10) +       # Monetização clara (10%)
     ($s.self_service * 5)) / 100 | floor;  # Zero suporte (5%)

# ============================================================
# HELPER FUNCTIONS
# ============================================================

def promotion_difficulty:
    if . >= 75 then "Orgânico - TikTok/Instagram viral"
    elif . >= 60 then "Orgânico - conteúdo educativo"
    elif . >= 40 then "Médio - precisa de estratégia"
    else "Difícil - precisa de vendas/paid"
    end;

def implementation_time:
    . as $s |
    if $s.implementation >= 80 then "1-2 semanas"
    elif $s.implementation >= 60 then "3-4 semanas"
    elif $s.implementation >= 40 then "1-2 meses"
    else "> 2 meses (complexo)"
    end;

def complexity_level:
    if . >= 70 then "baixa - APIs prontas"
    elif . < 40 then "alta - precisa de ML/infra"
    else "média - desenvolvimento moderado"
    end;

def infra_cost:
    . as $product |
    ($product | all_text) as $text |
    if $text | test("static|serverless|browser extension|api wrapper"; "i") then "10-20"
    elif $text | test("generator|chatbot|text|content"; "i") then "20-30"
    elif $text | test("automation|workflow|integration"; "i") then "30-50"
    elif $text | test("video|image processing|real-time"; "i") then "100-200"
    elif $text | test("platform|infrastructure|hosting"; "i") then "200-500"
    else "30-50"
    end;

def revenue_model:
    . as $product |
    ($product | all_text) as $text |
    if $text | test("generator|tool|assistant"; "i") then "Freemium R$19-29/mês"
    elif $text | test("template|pack|bundle"; "i") then "One-time R$29-49"
    elif $text | test("credits|pay per use"; "i") then "Créditos R$10-50"
    elif $text | test("enterprise|b2b"; "i") then "B2B - não recomendado"
    else "Freemium R$9-19/mês"
    end;

def target_audience:
    . as $product |
    ($product | all_text) as $text |
    if $text | test("instagram|tiktok|reels|conteúdo|creator"; "i") then "Criadores de conteúdo BR"
    elif $text | test("pdf|resumo|estudo|prova|vestibular|enem|universit"; "i") then "Estudantes universitários BR"
    elif $text | test("pequeno comércio|autônomo|whatsapp bot|faq|menu|cardápio"; "i") then "Pequenos comércios/autônomos"
    elif $text | test("currículo|vaga|entrevista|resume"; "i") then "Profissionais em busca de emprego"
    elif $text | test("aluguel|contrato"; "i") then "Pessoas físicas/pequenos proprietários"
    elif $text | test("freelancer"; "i") then "Freelancers BR"
    elif $text | test("linkedin|professional"; "i") then "Profissionais BR"
    else "Consumidor final brasileiro"
    end;

# ============================================================
# APPLY FILTERS - EXCLUDE NON-B2C PRODUCTS
# ============================================================

def apply_filters:
    . as $item |
    $item.scores as $s |
    $item.blue_ocean_status as $bos |
    (($item.description // "") + " " + ($item.name // "") + " " + ($item.category // "")) as $text |

    # Check each B2C filter (order matters - check most important first)
    (if $text | test("api platform|sdk|framework|library|infrastructure|hosting|deployment|cloud service|docker|kubernetes|developer tool"; "i") then "❌ Infraestrutura/plataforma dev - não é B2C"
     elif $text | test("enterprise|b2b|corporate|large team|sales team|consulting"; "i") then "❌ B2B/Enterprise - não é consumidor final"
     elif $text | test("medical|health|doctor|hospital|financial|banking|investment|legal|lawyer|saúde|financeiro|jurídico"; "i") then "❌ Setor regulamentado"
     elif $text | test("chatgpt|notion|slack|figma|canva|google|facebook|microsoft|openai"; "i") then "❌ Compete com big techs"
     elif $bos == "red" then "❌ Mar vermelho - concorrência forte"
     elif $s.pain_br < 35 then "❌ Não resolve dor do brasileiro (\($s.pain_br)/100)"
     elif $s.implementation < 40 then "❌ Muito complexo para solo founder (\($s.implementation)/100)"
     elif (($item.infra_cost | split("-")[1] | tonumber) > 50) then "❌ Custo infra alto (>$50/mês)"
     elif $s.self_service < 30 then "❌ Precisa de vendas/suporte intensivo"
     else null
     end) as $discard_reason |

    {
        passed_filters: ($discard_reason == null),
        discard_reason: ($discard_reason // "")
    };

# ============================================================
# GENERATE BR OPPORTUNITY ANALYSIS
# ============================================================

def br_opportunity:
    . as $item |
    $item.scores as $s |
    $item.blue_ocean_status as $bos |
    $item.target_audience as $audience |

    "Produto B2C para \($audience). " +
    (if $s.pain_br >= 75 then "Resolve dor real e específica do brasileiro. "
     elif $s.pain_br >= 60 then "Endereça necessidade comum no mercado BR. "
     else "" end) +
    (if $bos == "green" then "Pouca ou nenhuma concorrência local - mar azul real. "
     elif $bos == "yellow" then "Concorrência existe mas deixa gaps de execução. "
     else "" end) +
    (if $s.promotion >= 75 then "Fácil de promover organicamente no TikTok/Instagram. "
     elif $s.promotion >= 60 then "Promoção orgânica viável com conteúdo educativo. "
     else "" end) +
    (if $s.implementation >= 75 then "Implementável em 1-2 semanas usando APIs prontas."
     elif $s.implementation >= 60 then "Viável em 3-4 semanas para solo founder."
     else "" end);

# ============================================================
# GENERATE NEXT STEPS
# ============================================================

def next_steps:
    . as $item |
    $item.scores as $s |
    $item.target_audience as $audience |

    (if $s.implementation >= 75 then "Criar MVP em 1-2 semanas"
     else "Planejar MVP de 3-4 semanas"
     end) + ", " +
    (if $s.promotion >= 75 then "testar com 50-100 usuários via TikTok orgânico"
     else "validar com 30-50 usuários em comunidades (Tabnews, grupos Facebook)"
     end) + ", " +
    "iterar baseado em feedback antes de escalar.";

# ============================================================
# GENERATE RECOMMENDATION
# ============================================================

def recommendation:
    if . >= 75 then "🔥 ALTA PRIORIDADE - Oportunidade B2C real, implementar imediatamente"
    elif . >= 65 then "⭐ BOA OPORTUNIDADE - Validar demanda com MVP simples"
    elif . >= 55 then "💡 POTENCIAL - Pesquisar concorrência BR antes"
    else "🔍 AVALIAR - Manter no radar, mas não priorizar"
    end;

# ============================================================
# MAIN PROCESSING
# ============================================================

.products | map(
    . as $product |
    calculate_scores as $scores |
    ($scores | blue_ocean_status) as $bos |
    {
        name: $product.name,
        description: $product.description,
        category: ($product.category // "general"),
        source: ($product.source // "unknown"),
        url: ($product.url // ""),
        scores: $scores,
        blue_ocean_status: $bos,
        blue_ocean_emoji: ($bos | blue_ocean_emoji),
        blue_ocean_reason: ($product | blue_ocean_reason),
        final_score: ($scores | final_score),
        promotion_difficulty: ($scores.promotion | promotion_difficulty),
        implementation_time: ($scores | implementation_time),
        technical_complexity: ($scores.implementation | complexity_level),
        infra_cost: ($product | infra_cost),
        revenue_model: ($product | revenue_model),
        target_audience: ($product | target_audience)
    } |
    . + {
        br_opportunity: (. | br_opportunity),
        next_steps: (. | next_steps)
    } |
    . + (. | apply_filters) |
    . + {
        recommendation: (.final_score | recommendation)
    }
) | sort_by(.final_score) | reverse
' "$INPUT_FILE" > /tmp/analyzed-products.json

# Create final output with timestamp
jq --arg ts "$(date -Iseconds)" '{
    products: .,
    timestamp: $ts
}' /tmp/analyzed-products.json > "$OUTPUT_FILE"

# Stats
PASSED=$(jq '[.products[] | select(.passed_filters == true)] | length' "$OUTPUT_FILE")
DISCARDED=$(jq '[.products[] | select(.passed_filters == false)] | length' "$OUTPUT_FILE")

log "Analysis complete!"
log "Total analyzed: $TOTAL"
log "Passed B2C filters: $PASSED"
log "Discarded (not B2C): $DISCARDED"
log "Output saved to: $OUTPUT_FILE"

exit 0
