#!/bin/bash
#
# AI Opportunity Radar - Analysis Engine
# Analisa produtos coletados com scores e filtros
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

log "Analyzing products from: $INPUT_FILE"

# Get total products
TOTAL=$(jq '.products | length' "$INPUT_FILE")
log "Total products to analyze: $TOTAL"

# Create output file with jq processing all products at once
log "Processing products..."

jq '
# Scoring function - calculates scores based on text analysis
def calculate_scores:
    . as $product |
    {
        # Solo Founder Viability (0-100)
        solo_founder: (
            if ($product.description + " " + $product.name + " " + $product.category) | test("hardware|robot|medical|financial|legal|banking|healthcare|saúde|financeiro"; "i") then 30
            elif ($product.description + " " + $product.category) | test("api|automation|chat|assistant|generator|tool|automação"; "i") then 85
            else 70
            end
        ),
        
        # Promotion Ease (0-100)
        promotion: (
            if ($product.description + " " + $product.category) | test("writing|content|seo|marketing|social media|conteúdo"; "i") then 80
            elif ($product.description + " " + $product.category) | test("enterprise|b2b|sales|vendas"; "i") then 50
            else 60
            end
        ),
        
        # Blue Ocean - Competition (0-100)
        blue_ocean: (
            if ($product.description + " " + $product.name) | test("chatgpt|notion|slack|figma|canva"; "i") then 20
            elif ($product.category) | test("writing|image-generation"; "i") then 35
            elif ($product.description) | test("brazil|brasil|latam|portuguese"; "i") then 75
            else 50
            end
        ),
        
        # Real Pain Point for BR (0-100)
        pain_br: (
            if ($product.description) | test("small business|pme|autonomo|freelancer|bureaucracy|burocracia|invoice|nota fiscal|imposto"; "i") then 85
            elif ($product.description + " " + $product.category) | test("productivity|automation|assistant|produtividade"; "i") then 70
            else 50
            end
        ),
        
        # Innovation (0-100)
        innovation: (
            if ($product.description) | test("first|novel|unique|revolutionary|new approach|inédito"; "i") then 80
            elif ($product.description) | test("alternative to|clone|similar to|like|similar"; "i") then 30
            else 50
            end
        ),
        
        # Revenue Potential (0-100)
        revenue: (
            if ($product.description + " " + $product.category) | test("enterprise|business|b2b|team|empresa"; "i") then 75
            elif ($product.description) | test("free|open source|gratuito"; "i") then 30
            else 50
            end
        ),
        
        # Technical Complexity (0-100, higher = easier)
        complexity: (
            if ($product.description) | test("api|wrapper|integration|plugin|extension|integração"; "i") then 80
            elif ($product.description) | test("real-time|streaming|ml model|custom ai|video processing"; "i") then 30
            else 50
            end
        ),
        
        # Maintenance Cost (0-100, higher = lower cost)
        maintenance: (
            if ($product.description) | test("api wrapper|browser extension|static"; "i") then 90
            elif ($product.description) | test("video|image processing|real-time|ml"; "i") then 40
            else 60
            end
        ),
        
        # Cultural Fit (0-100)
        cultural: (
            if ($product.description) | test("pix|boleto|nota fiscal|cpf|cnpj"; "i") then 95
            elif ($product.description) | test("portuguese|pt-br|brazil|brasil"; "i") then 85
            else 60
            end
        )
    };

# Determine blue ocean status
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
    if ($product.description + " " + $product.name) | test("chatgpt|notion|slack|figma|canva"; "i") then "Competes with major players"
    elif ($product.category) | test("writing|image-generation"; "i") then "Crowded category, need differentiation"
    elif ($product.description) | test("brazil|brasil|latam|portuguese"; "i") then "BR-focused opportunity"
    else "Needs verification"
    end;

# Calculate final weighted score
def final_score:
    . as $s |
    (($s.solo_founder * 15) +
     ($s.promotion * 15) +
     ($s.blue_ocean * 15) +
     ($s.pain_br * 15) +
     ($s.innovation * 10) +
     ($s.revenue * 10) +
     ($s.complexity * 10) +
     ($s.maintenance * 5) +
     ($s.cultural * 5)) / 100 | floor;

# Determine promotion difficulty
def promotion_difficulty:
    if . >= 70 then "fácil"
    elif . < 50 then "difícil"
    else "médio"
    end;

# Determine technical complexity level
def complexity_level:
    if . >= 70 then "baixa"
    elif . < 40 then "alta"
    else "média"
    end;

# Estimate infra cost
def infra_cost:
    . as $product |
    if ($product.description) | test("api wrapper|browser extension|static"; "i") then "20"
    elif ($product.description) | test("video|image processing|real-time|ml"; "i") then "150"
    else "50"
    end;

# Revenue potential type
def revenue_potential:
    . as $product |
    if ($product.description + " " + $product.category) | test("enterprise|business|b2b|team"; "i") then "B2B SaaS"
    elif ($product.description) | test("free|open source"; "i") then "Freemium"
    else "B2C SaaS"
    end;

# Apply filters and determine pass/fail
def apply_filters:
    . as $item |
    $item.scores as $s |
    $item.blue_ocean_status as $bos |
    $item.product as $p |
    
    # Check each filter
    (if $s.solo_founder < 40 then "Solo Founder score too low (\($s.solo_founder)/100)"
     elif $bos == "red" then "Mar vermelho - concorrência forte"
     elif ($p.description + " " + $p.name + " " + $p.category) | test("medical|health|financial|banking|legal|lawyer|doctor|saúde|financeiro|jurídico"; "i") then "Setor regulamentado"
     elif ($item.infra_cost | tonumber) > 200 then "Custo infra alto (>$200/mês)"
     else null
     end) as $discard_reason |
    
    {
        passed_filters: ($discard_reason == null),
        discard_reason: ($discard_reason // "")
    };

# Generate BR opportunity analysis
def br_opportunity:
    . as $item |
    $item.scores as $s |
    $item.blue_ocean_status as $bos |
    
    "Produto com potencial para o mercado brasileiro. " +
    (if $s.pain_br >= 70 then "Resolve dor real identificada no mercado. " else "" end) +
    (if $bos == "green" then "Pouca ou nenhuma concorrência local. "
     elif $bos == "yellow" then "Concorrência existe mas com falhas de execução. "
     else "" end);

# Generate recommendation
def recommendation:
    if . >= 70 then "ALTA PRIORIDADE - Investigar imediatamente"
    elif . >= 60 then "MÉDIA PRIORIDADE - Pesquisar concorrência BR"
    elif . >= 50 then "BAIXA PRIORIDADE - Manter no radar"
    else "Avaliar em detalhes"
    end;

# Main processing
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
        technical_complexity: ($scores.complexity | complexity_level),
        infra_cost: ($product | infra_cost),
        revenue_potential: ($product | revenue_potential)
    } |
    . + {
        br_opportunity: (. | br_opportunity)
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
log "Passed filters: $PASSED"
log "Discarded: $DISCARDED"
log "Output saved to: $OUTPUT_FILE"

exit 0
