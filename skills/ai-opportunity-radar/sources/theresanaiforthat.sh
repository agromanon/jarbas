#!/bin/bash
#
# Source: There's An AI For That (theresanaiforthat.com)
# Coleta produtos de IA em destaque
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(dirname "$(ls -td /tmp/radar-*/ 2>/dev/null | head -1)")
OUTPUT_FILE="$TEMP_DIR/source-theresanaiforthat.json"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

log() {
    echo "[theresanaiforthat] $1"
}

# Initialize output
echo '{"source": "theresanaiforthat", "products": []}' > "$OUTPUT_FILE"

collect_products() {
    local url="$1"
    local category="$2"
    
    log "Fetching: $url"
    
    # Fetch page with delay to be respectful
    sleep 2
    
    HTML=$(curl -s -L \
        -H "User-Agent: $USER_AGENT" \
        -H "Accept: text/html,application/xhtml+xml" \
        --max-time 30 \
        "$url" 2>/dev/null || echo "")
    
    if [ -z "$HTML" ]; then
        log "Warning: Empty response from $url"
        return
    fi
    
    # Extract product data from HTML
    # Looking for common patterns in AI directory sites
    PRODUCTS=$(echo "$HTML" | grep -oP '(?<=<a[^>]*href=")[^"]*"(?=>[^<]*</a>)' 2>/dev/null || echo "")
    
    # Parse product cards (generic pattern for directory sites)
    echo "$HTML" | grep -oP '<div[^>]*class="[^"]*product[^"]*"[^>]*>.*?</div>' 2>/dev/null | while read -r card; do
        NAME=$(echo "$card" | grep -oP '(?<=<h[23][^>]*>)[^<]+' | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        DESC=$(echo "$card" | grep -oP '(?<=<p[^>]*>)[^<]+' | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        LINK=$(echo "$card" | grep -oP '(?<=href=")[^"]+' | head -1)
        
        if [ -n "$NAME" ] && [ "$NAME" != "" ]; then
            # Add to products array using jq
            jq --arg name "$NAME" \
               --arg desc "$DESC" \
               --arg link "$LINK" \
               --arg cat "$category" \
               '.products += [{
                   name: $name,
                   description: $desc,
                   url: $link,
                   category: $cat,
                   source: "theresanaiforthat"
               }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
        fi
    done
    
    # Alternative: Extract from JSON-LD or structured data
    JSON_LD=$(echo "$HTML" | grep -oP '(?<=<script type="application/ld\+json">).*?(?=</script>)' 2>/dev/null || echo "")
    if [ -n "$JSON_LD" ]; then
        echo "$JSON_LD" | jq -r '.itemListElement[]? | .name // empty' 2>/dev/null | while read -r name; do
            if [ -n "$name" ]; then
                jq --arg name "$name" \
                   --arg cat "$category" \
                   '.products += [{
                       name: $name,
                       description: "",
                       url: "",
                       category: $cat,
                       source: "theresanaiforthat"
                   }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
            fi
        done
    fi
}

# Collect trending/new AI tools
log "Collecting from There's An AI For That..."

# Homepage - trending tools
collect_products "https://theresanaiforthat.com/" "trending"

# New tools page
collect_products "https://theresanaiforthat.com/new/" "new"

# Popular categories (sample)
sleep 1
collect_products "https://theresanaiforthat.com/?cat=writing" "writing"
sleep 1
collect_products "https://theresanaiforthat.com/?cat=productivity" "productivity"
sleep 1
collect_products "https://theresanaiforthat.com/?cat=marketing" "marketing"
sleep 1
collect_products "https://theresanaiforthat.com/?cat=developer" "developer"

# Deduplicate
jq '.products |= unique_by(.name | ascii_downcase)' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

PRODUCT_COUNT=$(jq '.products | length' "$OUTPUT_FILE")
log "Collected $PRODUCT_COUNT products from There's An AI For That"

exit 0
