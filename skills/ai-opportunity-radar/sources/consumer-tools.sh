#!/bin/bash
#
# Source: There's An AI For That - Consumer Focus
# Coleta produtos de IA para CONSUMIDOR FINAL (não DevTools)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find or create temp directory
TEMP_DIR=$(ls -td /tmp/radar-*/ 2>/dev/null | head -1)
if [ -z "$TEMP_DIR" ] || [ ! -d "$TEMP_DIR" ]; then
    TEMP_DIR="/tmp/radar-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$TEMP_DIR"
fi
# Remove trailing slash if present
TEMP_DIR="${TEMP_DIR%/}"

OUTPUT_FILE="$TEMP_DIR/source-consumer-tools.json"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

log() {
    echo "[consumer-tools] $1"
}

# Initialize output
echo '{"source": "consumer-tools", "products": []}' > "$OUTPUT_FILE"

# ============================================
# B2C CATEGORIES TO SCRAPE
# Focus on consumer-facing tools, NOT developer/enterprise
# ============================================

B2C_CATEGORIES=(
    # Content Creation (high B2C potential)
    "social-media"
    "content-creation"
    "writing-assistant"
    "video-editing"
    "image-generation"
    "audio-generation"
    
    # Personal Tools
    "personal-assistant"
    "productivity"
    "education"
    "lifestyle"
    "travel"
    "health-fitness"
    
    # Creative/Fun
    "design"
    "photo-editing"
    "music"
    "entertainment"
    
    # Practical B2C
    "resume"
    "job-search"
    "finance-personal"
    "shopping"
)

# Categories to EXPLICITLY SKIP (not B2C)
EXCLUDED_PATTERNS=(
    "api"
    "developer"
    "devops"
    "infrastructure"
    "enterprise"
    "database"
    "hosting"
    "framework"
    "sdk"
    "analytics-enterprise"
    "security-enterprise"
)

collect_category() {
    local category="$1"
    local url="https://theresanaiforthat.com/s/${category}/"
    
    log "Fetching category: $category"
    
    sleep 2
    
    HTML=$(curl -s -L \
        -H "User-Agent: $USER_AGENT" \
        -H "Accept: text/html,application/xhtml+xml" \
        --max-time 30 \
        "$url" 2>/dev/null || echo "")
    
    if [ -z "$HTML" ]; then
        log "Warning: Empty response for $category"
        return
    fi
    
    # Extract product data from the page
    # There's An AI For That has product cards with names and descriptions
    
    # Method 1: Look for JSON-LD structured data
    JSON_LD=$(echo "$HTML" | grep -oP '(?<=<script type="application/ld\+json">).*?(?=</script>)' 2>/dev/null | head -1 || echo "")
    
    if [ -n "$JSON_LD" ]; then
        echo "$JSON_LD" | jq -r '
            .itemListElement[]? // 
            .mainEntity.itemListElement[]? //
            empty
        ' 2>/dev/null | while read -r item; do
            NAME=$(echo "$item" | jq -r '.name // .item.name // empty' 2>/dev/null)
            DESC=$(echo "$item" | jq -r '.description // .item.description // empty' 2>/dev/null)
            URL=$(echo "$item" | jq -r '.url // .item.url // empty' 2>/dev/null)
            
            if [ -n "$NAME" ] && [ "$NAME" != "null" ]; then
                # Check if it's B2C (not excluded)
                IS_B2C=true
                for pattern in "${EXCLUDED_PATTERNS[@]}"; do
                    if echo "$NAME $DESC" | grep -qi "$pattern"; then
                        IS_B2C=false
                        break
                    fi
                done
                
                if [ "$IS_B2C" = true ]; then
                    jq --arg name "$NAME" \
                       --arg desc "$DESC" \
                       --arg url "$URL" \
                       --arg cat "$category" \
                       '.products += [{
                           name: $name,
                           description: $desc,
                           url: $url,
                           category: $cat,
                           source: "consumer-tools"
                       }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
                fi
            fi
        done
    fi
    
    # Method 2: Parse HTML product cards (fallback)
    echo "$HTML" | grep -oP '<article[^>]*>.*?</article>|<div[^>]*class="[^"]*tool[^"]*"[^>]*>.*?</div>' 2>/dev/null | head -20 | while read -r card; do
        NAME=$(echo "$card" | grep -oP '(?<=<h[234][^>]*>)[^<]+' | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | recode html..ascii 2>/dev/null || echo "$card" | grep -oP '(?<=<h[234][^>]*>)[^<]+' | head -1)
        DESC=$(echo "$card" | grep -oP '(?<=<p[^>]*>)[^<]+' | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | recode html..ascii 2>/dev/null || echo "")
        LINK=$(echo "$card" | grep -oP '(?<=href=")[^"]+' | head -1)
        
        if [ -n "$NAME" ] && [ ${#NAME} -gt 2 ]; then
            # Check B2C filter
            IS_B2C=true
            for pattern in "${EXCLUDED_PATTERNS[@]}"; do
                if echo "$NAME $DESC" | grep -qi "$pattern"; then
                    IS_B2C=false
                    break
                fi
            done
            
            if [ "$IS_B2C" = true ]; then
                jq --arg name "$NAME" \
                   --arg desc "$DESC" \
                   --arg link "$LINK" \
                   --arg cat "$category" \
                   '.products += [{
                       name: $name,
                       description: $desc,
                       url: $link,
                       category: $cat,
                       source: "consumer-tools"
                   }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
            fi
        fi
    done
}

# ============================================
# MAIN COLLECTION
# ============================================

log "Collecting B2C consumer tools from There's An AI For That..."

# Collect from homepage (trending)
log "Fetching homepage trending..."
sleep 1
HTML=$(curl -s -L \
    -H "User-Agent: $USER_AGENT" \
    --max-time 30 \
    "https://theresanaiforthat.com/" 2>/dev/null || echo "")

if [ -n "$HTML" ]; then
    # Parse trending products
    echo "$HTML" | grep -oP '<div[^>]*class="[^"]*tool[^"]*"[^>]*>.*?</div>' 2>/dev/null | head -15 | while read -r card; do
        NAME=$(echo "$card" | grep -oP '(?<=<h[234][^>]*>)[^<]+' | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        DESC=$(echo "$card" | grep -oP '(?<=<p[^>]*>)[^<]+' | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [ -n "$NAME" ] && [ ${#NAME} -gt 2 ]; then
            IS_B2C=true
            for pattern in "${EXCLUDED_PATTERNS[@]}"; do
                if echo "$NAME $DESC" | grep -qi "$pattern"; then
                    IS_B2C=false
                    break
                fi
            done
            
            if [ "$IS_B2C" = true ]; then
                jq --arg name "$NAME" \
                   --arg desc "$DESC" \
                   --arg cat "trending" \
                   '.products += [{
                       name: $name,
                       description: $desc,
                       url: "",
                       category: $cat,
                       source: "consumer-tools"
                   }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
            fi
        fi
    done
fi

# Collect from B2C categories
for category in "${B2C_CATEGORIES[@]}"; do
    collect_category "$category"
    sleep 1
done

# ============================================
# DEDUPLICATION AND CLEANUP
# ============================================

# Remove duplicates by name (case-insensitive)
jq '.products |= unique_by(.name | ascii_downcase)' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

# Remove products with empty names
jq '.products |= [.[] | select(.name != "" and .name != null)]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

PRODUCT_COUNT=$(jq '.products | length' "$OUTPUT_FILE")
log "Collected $PRODUCT_COUNT B2C consumer tools"

exit 0
