#!/bin/bash
#
# Source: Future Tools (futuretools.io)
# Coleta ferramentas de IA emergentes por categoria
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(dirname "$(ls -td /tmp/radar-*/ 2>/dev/null | head -1)")
OUTPUT_FILE="$TEMP_DIR/source-futuretools.json"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

log() {
    echo "[futuretools] $1"
}

# Initialize output
echo '{"source": "futuretools", "products": []}' > "$OUTPUT_FILE"

collect_from_page() {
    local url="$1"
    local category="$2"
    
    log "Fetching: $url"
    
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
    
    # Try to find JSON data (Next.js or similar frameworks)
    NEXT_DATA=$(echo "$HTML" | grep -oP '(?<=<script id="__NEXT_DATA__" type="application/json">).*?(?=</script>)' 2>/dev/null || echo "")
    
    if [ -n "$NEXT_DATA" ]; then
        echo "$NEXT_DATA" | jq -r '
            .props.pageProps.tools[]? //
            .props.initialProps.tools[]? //
            .props.pageProps.categories[].tools[]? //
            []
        ' 2>/dev/null | jq -c 'select(.name != null)' 2>/dev/null | while read -r tool; do
            NAME=$(echo "$tool" | jq -r '.name // empty')
            DESC=$(echo "$tool" | jq -r '.description // .tagline // empty')
            LINK=$(echo "$tool" | jq -r '.url // .link // .website // empty')
            PRICING=$(echo "$tool" | jq -r '.pricing // .price // empty')
            FEATURED=$(echo "$tool" | jq -r '.featured // false')
            
            if [ -n "$NAME" ]; then
                jq --arg name "$NAME" \
                   --arg desc "$DESC" \
                   --arg link "$LINK" \
                   --arg pricing "$PRICING" \
                   --arg featured "$FEATURED" \
                   --arg cat "$category" \
                   '.products += [{
                       name: $name,
                       description: $desc,
                       url: $link,
                       category: $cat,
                       source: "futuretools",
                       pricing: $pricing,
                       featured: ($featured == "true")
                   }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
            fi
        done
    fi
    
    # Fallback: Parse HTML for tool cards
    echo "$HTML" | grep -oP '<div[^>]*class="[^"]*(?:tool|card|item)[^"]*"[^>]*>.*?</div>' 2>/dev/null | while read -r card; do
        NAME=$(echo "$card" | grep -oP '(?<=<h[234][^>]*>)[^<]+' | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        DESC=$(echo "$card" | grep -oP '(?<=<p[^>]*>)[^<]+' | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        LINK=$(echo "$card" | grep -oP '(?<=href=")[^"]+' | head -1)
        
        if [ -n "$NAME" ] && [ "$NAME" != "" ]; then
            jq --arg name "$NAME" \
               --arg desc "$DESC" \
               --arg link "$LINK" \
               --arg cat "$category" \
               '.products += [{
                   name: $name,
                   description: $desc,
                   url: $link,
                   category: $cat,
                   source: "futuretools"
               }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
        fi
    done
    
    # Also look for JSON-LD structured data
    JSON_LD=$(echo "$HTML" | grep -oP '(?<=<script type="application/ld\+json">).*?(?=</script>)' 2>/dev/null || echo "")
    if [ -n "$JSON_LD" ]; then
        echo "$JSON_LD" | jq -r '.itemListElement[]? | .item // empty' 2>/dev/null | while read -r item; do
            NAME=$(echo "$item" | jq -r '.name // empty' 2>/dev/null)
            DESC=$(echo "$item" | jq -r '.description // empty' 2>/dev/null)
            
            if [ -n "$NAME" ]; then
                jq --arg name "$NAME" \
                   --arg desc "$DESC" \
                   --arg cat "$category" \
                   '.products += [{
                       name: $name,
                       description: $desc,
                       url: "",
                       category: $cat,
                       source: "futuretools"
                   }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
            fi
        done
    fi
}

# Collect from Future Tools
log "Collecting from Future Tools..."

# Homepage - trending/new
collect_from_page "https://futuretools.io/" "trending"

# Categories (sample of popular AI tool categories)
sleep 1
collect_from_page "https://futuretools.io/categories/writing" "writing"
sleep 1
collect_from_page "https://futuretools.io/categories/image-generation" "image-generation"
sleep 1
collect_from_page "https://futuretools.io/categories/video" "video"
sleep 1
collect_from_page "https://futuretools.io/categories/audio" "audio"
sleep 1
collect_from_page "https://futuretools.io/categories/productivity" "productivity"
sleep 1
collect_from_page "https://futuretools.io/categories/chatbots" "chatbots"
sleep 1
collect_from_page "https://futuretools.io/categories/developer-tools" "developer-tools"

# New tools page if available
sleep 1
collect_from_page "https://futuretools.io/new" "new"

# Deduplicate
jq '.products |= unique_by(.name | ascii_downcase)' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

# Sort featured first, then by name
jq '.products |= sort_by([.featured, .name]) | reverse' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

PRODUCT_COUNT=$(jq '.products | length' "$OUTPUT_FILE")
log "Collected $PRODUCT_COUNT products from Future Tools"

exit 0
