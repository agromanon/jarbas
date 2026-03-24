#!/bin/bash
#
# AI Opportunity Radar - B2C Brasil Edition
# Coleta, analisa e envia relatório de oportunidades B2C para o mercado BR
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_DIR="$SCRIPT_DIR/sources"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
TEMP_DIR="/tmp/radar-$TIMESTAMP"

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Parse arguments
COLLECT=true
ANALYZE=true
SEND=true
REPORT_FILE=""
INPUT_PRODUCTS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --collect-only)
            ANALYZE=false
            SEND=false
            shift
            ;;
        --analyze-only)
            COLLECT=false
            SEND=false
            shift
            ;;
        --send-only)
            COLLECT=false
            ANALYZE=false
            REPORT_FILE="$2"
            shift 2
            ;;
        --input)
            INPUT_PRODUCTS="$2"
            COLLECT=false
            shift 2
            ;;
        --help)
            echo "Usage: radar.sh [OPTIONS]"
            echo ""
            echo "AI Opportunity Radar - B2C Brasil Edition"
            echo ""
            echo "Options:"
            echo "  --collect-only       Only collect data from sources"
            echo "  --analyze-only       Only analyze existing data"
            echo "  --input FILE         Analyze specific products.json file"
            echo "  --send-only FILE     Only send existing report"
            echo "  --help               Show this help"
            echo ""
            echo "Environment Variables:"
            echo "  RADAR_TELEGRAM_BOT_TOKEN  Telegram bot token"
            echo "  RADAR_TELEGRAM_CHAT_ID    Target chat ID"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create temp directory
mkdir -p "$TEMP_DIR"
log "Created temp directory: $TEMP_DIR"

# Initialize files
PRODUCTS_FILE="$TEMP_DIR/products.json"
ANALYZED_FILE="$TEMP_DIR/analyzed.json"
REPORT_FILE_FINAL="$TEMP_DIR/report.md"
COLLECT_LOG="$TEMP_DIR/collect.log"
ANALYZE_LOG="$TEMP_DIR/analyze.log"

echo '{"products": [], "timestamp": "'"$TIMESTAMP"'"}' > "$PRODUCTS_FILE"

# ============================================
# STEP 1: COLLECT DATA FROM B2C SOURCES
# ============================================

if [ "$COLLECT" = true ]; then
    log "Starting B2C data collection..."
    
    # Collect from Consumer Tools (There's An AI For That - B2C filtered)
    if [ -f "$SOURCES_DIR/consumer-tools.sh" ]; then
        log "Collecting from Consumer Tools (There's An AI For That)..."
        if bash "$SOURCES_DIR/consumer-tools.sh" >> "$COLLECT_LOG" 2>&1; then
            log "✓ Consumer Tools collected"
        else
            log "✗ Failed to collect from Consumer Tools"
        fi
    fi
    
    # Collect from Product Hunt B2C
    if [ -f "$SOURCES_DIR/producthunt-b2c.sh" ]; then
        log "Collecting from Product Hunt (B2C filter)..."
        if bash "$SOURCES_DIR/producthunt-b2c.sh" >> "$COLLECT_LOG" 2>&1; then
            log "✓ Product Hunt B2C collected"
        else
            log "✗ Failed to collect from Product Hunt"
        fi
    fi
    
    # Collect from Reddit Pain Points
    if [ -f "$SOURCES_DIR/reddit-painpoints.sh" ]; then
        log "Collecting from Reddit (pain points)..."
        if bash "$SOURCES_DIR/reddit-painpoints.sh" >> "$COLLECT_LOG" 2>&1; then
            log "✓ Reddit pain points collected"
        else
            log "✗ Failed to collect from Reddit"
        fi
    fi
    
    # Collect from Social Trends
    if [ -f "$SOURCES_DIR/social-trends.sh" ]; then
        log "Collecting from Social Trends..."
        if bash "$SOURCES_DIR/social-trends.sh" >> "$COLLECT_LOG" 2>&1; then
            log "✓ Social Trends collected"
        else
            log "✗ Failed to collect from Social Trends"
        fi
    fi
    
    # Merge all products
    log "Merging collected products..."
    MERGED_PRODUCTS="[]"
    
    for source_file in "$TEMP_DIR"/source-*.json; do
        if [ -f "$source_file" ]; then
            SOURCE_PRODUCTS=$(cat "$source_file" | jq -r '.products // []')
            MERGED_PRODUCTS=$(echo "$MERGED_PRODUCTS" "$SOURCE_PRODUCTS" | jq -s 'add | unique_by(.name | ascii_downcase)')
        fi
    done
    
    echo '{"products": '"$MERGED_PRODUCTS"', "timestamp": "'"$TIMESTAMP"'"}' > "$PRODUCTS_FILE"
    
    PRODUCT_COUNT=$(cat "$PRODUCTS_FILE" | jq '.products | length')
    log "Collected $PRODUCT_COUNT products total"
fi

# ============================================
# STEP 2: ANALYZE PRODUCTS (B2C FOCUSED)
# ============================================

if [ "$ANALYZE" = true ]; then
    log "Starting B2C analysis..."
    
    # Use input file if provided
    if [ -n "$INPUT_PRODUCTS" ] && [ -f "$INPUT_PRODUCTS" ]; then
        PRODUCTS_FILE="$INPUT_PRODUCTS"
        log "Using input file: $PRODUCTS_FILE"
    elif [ ! -f "$PRODUCTS_FILE" ] || [ ! -s "$PRODUCTS_FILE" ]; then
        LATEST_PRODUCTS=$(ls -td /tmp/radar-*/products.json 2>/dev/null | head -1)
        if [ -n "$LATEST_PRODUCTS" ] && [ -f "$LATEST_PRODUCTS" ]; then
            PRODUCTS_FILE="$LATEST_PRODUCTS"
            log "Using latest products file: $PRODUCTS_FILE"
        else
            error "No products file found. Run with --collect-only first"
            exit 1
        fi
    fi
    
    PRODUCT_COUNT=$(cat "$PRODUCTS_FILE" | jq '.products | length')
    
    if [ -f "$SCRIPT_DIR/analyze-b2c.sh" ]; then
        if bash "$SCRIPT_DIR/analyze-b2c.sh" "$PRODUCTS_FILE" "$ANALYZED_FILE" >> "$ANALYZE_LOG" 2>&1; then
            log "✓ B2C Analysis completed"
        else
            error "Analysis failed"
            cat "$ANALYZE_LOG" >&2
            exit 1
        fi
    else
        error "analyze-b2c.sh not found"
        exit 1
    fi
    
    # Generate B2C report
    log "Generating B2C report..."
    
    PASSED_COUNT=$(cat "$ANALYZED_FILE" | jq '[.products[] | select(.passed_filters == true)] | length')
    B2C_COUNT=$(cat "$ANALYZED_FILE" | jq '[.products[] | select(.is_b2c == true)] | length')
    CHEAP_COUNT=$(cat "$ANALYZED_FILE" | jq '[.products[] | select(.passed_filters == true and .scores.maintenance_cost >= 60)] | length')
    FAST_COUNT=$(cat "$ANALYZED_FILE" | jq '[.products[] | select(.passed_filters == true and .scores.implementation_ease >= 70)] | length')
    
    DATE_STR=$(date +"%d/%m/%Y")
    
    # Build B2C report header
    {
        echo "🚀 RADAR OPORTUNIDADES B2C BRASIL - $DATE_STR"
        echo ""
        echo "📊 RESUMO"
        echo "• $PRODUCT_COUNT produtos analisados"
        echo "• $B2C_COUNT focados em consumidor final (B2C)"
        echo "• $FAST_COUNT implementáveis em < 4 semanas"
        echo "• $CHEAP_COUNT com custo < \$30/mês"
        echo ""
        echo "🏆 TOP 10 OPORTUNIDADES B2C"
        echo ""
    } > "$REPORT_FILE_FINAL"
    
    # Generate top 10 B2C opportunities with new format
    cat "$ANALYZED_FILE" | jq -r '
        [.products[] | select(.passed_filters == true)] |
        sort_by(.final_score) | reverse | .[0:10] |
        to_entries[] |
        "🎬 \(.key + 1)️⃣ \(.value.name)
   😰 Dor: \(.value.pain_description)
   👥 Público: \(.value.target_audience)
   🛠 Tempo: \(.value.implementation_time)
   💸 Custo: \(.value.estimated_cost)
   📱 Promoção: \(.value.promotion_channel)
   💰 Preço: \(.value.suggested_price)
   🌊 Concorrência: \(.value.competition.emoji) \(.value.competition.text)
   
   ✨ Por que funciona no BR:
   \(.value.why_works_br)
   
   🎯 MVP em 2 semanas:
   \(.value.mvp_description)
   
   📊 Score: \(.value.final_score)/100
   
"
    ' >> "$REPORT_FILE_FINAL"
    
    # Add discarded section
    {
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "📉 DESCARTADOS (e por quê)"
        echo ""
    } >> "$REPORT_FILE_FINAL"
    
    cat "$ANALYZED_FILE" | jq -r '
        [.products[] | select(.exclusion.excluded == true)] |
        .[0:15][] |
        "• \(.name): \(.discard_reason)"
    ' >> "$REPORT_FILE_FINAL"
    
    # Add recommendations section
    {
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "💡 COMEÇAR POR AQUI:"
    } >> "$REPORT_FILE_FINAL"
    
    # Get top 2 for recommendations
    cat "$ANALYZED_FILE" | jq -r '
        [.products[] | select(.passed_filters == true)] |
        sort_by(.final_score) | reverse | .[0:2] |
        to_entries[] |
        "\(.key + 1). \(.value.name) - \(if .value.scores.implementation_ease >= 70 and .value.scores.pain_brazilian >= 70 then "mais fácil + maior dor" else "segundo mais promissor" end)"
    ' >> "$REPORT_FILE_FINAL"
    
    # Add promotion channels
    {
        echo ""
        echo ""
        echo "📱 CANAIS DE PROMOÇÃO ORGÂNICA:"
        echo "• TikTok: tutoriais 30-60s mostrando resultado"
        echo "• Instagram Reels: antes/depois"
        echo "• Grupos Facebook/WhatsApp: nichos específicos"
        echo "• Reddit BR / Tabnews: comunidades engajadas"
        echo "• Product Hunt Brasil: lançamento inicial"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🔗 Fontes: Consumer Tools, Product Hunt B2C, Reddit, Social Trends"
        echo "📅 Gerado em: $(date '+%d/%m/%Y às %H:%M')"
        echo ""
        echo "_"
        echo "Foco total em B2C - consumidor final brasileiro_"
    } >> "$REPORT_FILE_FINAL"
    
    log "Report generated at: $REPORT_FILE_FINAL"
fi

# ============================================
# STEP 3: SEND REPORT
# ============================================

if [ "$SEND" = true ]; then
    if [ -n "$REPORT_FILE" ] && [ -f "$REPORT_FILE" ]; then
        REPORT_TO_SEND="$REPORT_FILE"
    else
        REPORT_TO_SEND="$REPORT_FILE_FINAL"
    fi
    
    if [ ! -f "$REPORT_TO_SEND" ]; then
        error "No report file found to send"
        exit 1
    fi
    
    log "Sending B2C report via Telegram..."
    
    if [ -f "$SCRIPT_DIR/telegram.sh" ]; then
        if bash "$SCRIPT_DIR/telegram.sh" "$REPORT_TO_SEND"; then
            log "✓ Report sent successfully"
        else
            error "Failed to send report"
            exit 1
        fi
    else
        error "telegram.sh not found"
        exit 1
    fi
fi

log "Radar B2C completed successfully!"
log "Temp files available at: $TEMP_DIR"

exit 0
