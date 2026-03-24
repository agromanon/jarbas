#!/bin/bash
#
# AI Opportunity Radar - Main orchestration script (B2C Focus)
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
            COLLECT=false  # Skip collection when input is provided
            shift 2
            ;;
        --help)
            echo "Usage: radar.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --collect-only       Only collect data from sources"
            echo "  --analyze-only       Only analyze existing data (uses latest products.json)"
            echo "  --input FILE         Analyze specific products.json file (skips collection)"
            echo "  --send-only FILE     Only send existing report"
            echo "  --help               Show this help"
            echo ""
            echo "Environment Variables (required for sending):"
            echo "  RADAR_TELEGRAM_BOT_TOKEN  Telegram bot token from @BotFather"
            echo "  RADAR_TELEGRAM_CHAT_ID    Target chat ID for notifications"
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

# Step 1: Collect data from sources
if [ "$COLLECT" = true ]; then
    log "Starting data collection..."
    
    # Collect from There's An AI For That
    if [ -f "$SOURCES_DIR/theresanaiforthat.sh" ]; then
        log "Collecting from There's An AI For That..."
        if bash "$SOURCES_DIR/theresanaiforthat.sh" >> "$COLLECT_LOG" 2>&1; then
            log "✓ There's An AI For That collected"
        else
            log "✗ Failed to collect from There's An AI For That"
        fi
    fi
    
    # Collect from Product Hunt
    if [ -f "$SOURCES_DIR/producthunt.sh" ]; then
        log "Collecting from Product Hunt..."
        if bash "$SOURCES_DIR/producthunt.sh" >> "$COLLECT_LOG" 2>&1; then
            log "✓ Product Hunt collected"
        else
            log "✗ Failed to collect from Product Hunt"
        fi
    fi
    
    # Collect from Reddit
    if [ -f "$SOURCES_DIR/reddit.sh" ]; then
        log "Collecting from Reddit..."
        if bash "$SOURCES_DIR/reddit.sh" >> "$COLLECT_LOG" 2>&1; then
            log "✓ Reddit collected"
        else
            log "✗ Failed to collect from Reddit"
        fi
    fi
    
    # Collect from Future Tools
    if [ -f "$SOURCES_DIR/futuretools.sh" ]; then
        log "Collecting from Future Tools..."
        if bash "$SOURCES_DIR/futuretools.sh" >> "$COLLECT_LOG" 2>&1; then
            log "✓ Future Tools collected"
        else
            log "✗ Failed to collect from Future Tools"
        fi
    fi
    
    # Merge all products
    log "Merging collected products..."
    MERGED_PRODUCTS="[]"
    
    for source_file in "$TEMP_DIR"/source-*.json; do
        if [ -f "$source_file" ]; then
            SOURCE_PRODUCTS=$(cat "$source_file" | jq -r '.products // []')
            MERGED_PRODUCTS=$(echo "$MERGED_PRODUCTS" "$SOURCE_PRODUCTS" | jq -s 'add | unique_by(.name)')
        fi
    done
    
    echo '{"products": '"$MERGED_PRODUCTS"', "timestamp": "'"$TIMESTAMP"'}}' > "$PRODUCTS_FILE"
    
    PRODUCT_COUNT=$(cat "$PRODUCTS_FILE" | jq '.products | length')
    log "Collected $PRODUCT_COUNT products total"
fi

# Step 2: Analyze products
if [ "$ANALYZE" = true ]; then
    log "Starting B2C analysis..."
    
    # Use input file if provided, otherwise use collected products
    if [ -n "$INPUT_PRODUCTS" ] && [ -f "$INPUT_PRODUCTS" ]; then
        PRODUCTS_FILE="$INPUT_PRODUCTS"
        log "Using input file: $PRODUCTS_FILE"
    elif [ ! -f "$PRODUCTS_FILE" ] || [ ! -s "$PRODUCTS_FILE" ]; then
        # Look for most recent products.json in /tmp/radar-* directories
        LATEST_PRODUCTS=$(ls -td /tmp/radar-*/products.json 2>/dev/null | head -1)
        if [ -n "$LATEST_PRODUCTS" ] && [ -f "$LATEST_PRODUCTS" ]; then
            PRODUCTS_FILE="$LATEST_PRODUCTS"
            log "Using latest products file: $PRODUCTS_FILE"
        else
            error "No products file found. Run with --collect-only first or provide --input FILE"
            exit 1
        fi
    fi
    
    PRODUCT_COUNT=$(cat "$PRODUCTS_FILE" | jq '.products | length')
    
    if [ -f "$SCRIPT_DIR/analyze.sh" ]; then
        if bash "$SCRIPT_DIR/analyze.sh" "$PRODUCTS_FILE" "$ANALYZED_FILE" >> "$ANALYZE_LOG" 2>&1; then
            log "✓ B2C analysis completed"
        else
            error "Analysis failed"
            cat "$ANALYZE_LOG" >&2
            exit 1
        fi
    else
        error "analyze.sh not found"
        exit 1
    fi
    
    # Generate B2C-focused report
    log "Generating B2C report..."
    
    PASSED_COUNT=$(cat "$ANALYZED_FILE" | jq '[.products[] | select(.passed_filters == true)] | length')
    DISCARDED_COUNT=$(cat "$ANALYZED_FILE" | jq '[.products[] | select(.passed_filters == false)] | length')
    BLUE_OCEAN_COUNT=$(cat "$ANALYZED_FILE" | jq '[.products[] | select(.passed_filters == true and .blue_ocean_status == "green")] | length')
    QUICK_WINS=$(cat "$ANALYZED_FILE" | jq '[.products[] | select(.passed_filters == true and .scores.implementation >= 75)] | length')
    
    DATE_STR=$(date +"%d/%m/%Y")
    
    # Build B2C report header
    {
        echo "🚀 RADAR DE OPORTUNIDADES B2C BR - $DATE_STR"
        echo ""
        echo "📊 RESUMO"
        echo "• $PRODUCT_COUNT produtos analisados"
        echo "• $PASSED_COUNT focados em B2C consumidor final"
        echo "• $QUICK_WINS com implementação < 4 semanas"
        echo "• $BLUE_OCEAN_COUNT mar azul real no BR"
        echo ""
        echo "🏆 TOP 10 OPORTUNIDADES B2C"
        echo ""
    } > "$REPORT_FILE_FINAL"
    
    # Generate top 10 B2C opportunities
    cat "$ANALYZED_FILE" | jq -r '
        [.products[] | select(.passed_filters == true)] |
        sort_by(.final_score) | reverse | .[0:10] |
        to_entries[] |
        "🎬 \(.key + 1)️⃣ \(.value.name)
   💡 O que é: \(.value.description[:100])
   😰 Dor que resolve: \(.value.target_audience)
   👥 Público: \(.value.target_audience)
   🛠 Implementação: \(.value.implementation_time)
   💸 Custo infra: ~$\(.value.infra_cost)/mês
   📱 Promoção: \(.value.promotion_difficulty)
   💰 Modelo: \(.value.revenue_model)
   🌊 Concorrência BR: \(.value.blue_ocean_emoji) \(.value.blue_ocean_reason)
   🏢 Solo founder: \(if .value.scores.implementation >= 60 then "✅ Sim" else "⚠️ Complexo" end)
   ⭐ Score: \(.value.final_score)/100
   
   ✨ Por que funciona no BR:
   \(.value.br_opportunity)
   
   🎯 Próximos passos:
   \(.value.next_steps)
"
    ' >> "$REPORT_FILE_FINAL"
    
    # Add discarded section
    {
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "📉 DESCARTADOS E POR QUÊ"
        echo ""
    } >> "$REPORT_FILE_FINAL"
    
    cat "$ANALYZED_FILE" | jq -r '
        [.products[] | select(.passed_filters == false)] |
        .[0:15][] |
        "• \(.name): \(.discard_reason)"
    ' >> "$REPORT_FILE_FINAL"
    
    # Add monetization ideas
    {
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "💰 IDEIAS DE MONETIZAÇÃO B2C"
        echo ""
        echo "• Freemium básico gratuito + premium R$19-29/mês"
        echo "• One-time payment R$29-49 (lifetime access)"
        echo "• Créditos pré-pagos (R$10 = 100 usos)"
        echo "• Assinatura anual com desconto (2 meses grátis)"
        echo ""
    } >> "$REPORT_FILE_FINAL"
    
    # Add organic promotion channels
    {
        echo "📱 CANAIS DE PROMOÇÃO ORGÂNICA"
        echo ""
        echo "• TikTok (tutoriais, antes/depois, dicas rápidas)"
        echo "• Instagram Reels (demonstrações, cases de uso)"
        echo "• Grupos de Facebook/WhatsApp (nichos específicos)"
        echo "• Fóruns (Reddit BR, Tabnews, Gumroad)"
        echo "• Product Hunt Brasil (lançamento)"
        echo "• YouTube Shorts (tutoriais em 60s)"
        echo ""
    } >> "$REPORT_FILE_FINAL"
    
    # Add footer
    {
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🔗 Fontes analisadas: There's An AI For That, Product Hunt, Reddit, Future Tools"
        echo "📅 Gerado em: $(date '+%d/%m/%Y às %H:%M')"
        echo "🎯 Foco: B2C consumidor final brasileiro"
    } >> "$REPORT_FILE_FINAL"
    
    log "B2C report generated at: $REPORT_FILE_FINAL"
fi

# Step 3: Send report
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

log "Radar completed successfully!"
log "Temp files available at: $TEMP_DIR"

exit 0
