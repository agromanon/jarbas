#!/bin/bash
#
# Source: Product Hunt
# Coleta lançamentos de IA dos últimos 7 dias
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(dirname "$(ls -td /tmp/radar-*/ 2>/dev/null | head -1)")
OUTPUT_FILE="$TEMP_DIR/source-producthunt.json"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

log() {
    echo "[producthunt] $1"
}

# Initialize output
echo '{"source": "producthunt", "products": []}' > "$OUTPUT_FILE"

collect_from_page() {
    local url="$1"
    
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
    
    # Product Hunt uses Next.js with __NEXT_DATA__
    NEXT_DATA=$(echo "$HTML" | grep -oP '(?<=<script id="__NEXT_DATA__" type="application/json">).*?(?=</script>)' 2>/dev/null || echo "")
    
    if [ -n "$NEXT_DATA" ]; then
        # Parse products from Next.js data
        echo "$NEXT_DATA" | jq -r '
            .props.pageProps.posts[]? // 
            .props.initialProps.posts[]? //
            .props.pageProps.sections[].posts[]? //
            []
        ' 2>/dev/null | jq -c 'select(.name != null)' 2>/dev/null | while read -r product; do
            NAME=$(echo "$product" | jq -r '.name // empty')
            DESC=$(echo "$product" | jq -r '.tagline // .description // empty')
            LINK=$(echo "$product" | jq -r '.url // .link // empty' | sed 's/^$/https:\/\/producthunt.com/')
            VOTES=$(echo "$product" | jq -r '.votesCount // .votes // 0')
            COMMENTS=$(echo "$product" | jq -r '.commentsCount // .comments // 0')
            TOPICS=$(echo "$product" | jq -r '[.topics[]?.name // empty] | join(", ") // empty')
            
            if [ -n "$NAME" ]; then
                jq --arg name "$NAME" \
                   --arg desc "$DESC" \
                   --arg link "$LINK" \
                   --arg votes "$VOTES" \
                   --arg comments "$COMMENTS" \
                   --arg topics "$TOPICS" \
                   '.products += [{
                       name: $name,
                       description: $desc,
                       url: $link,
                       category: "producthunt",
                       source: "producthunt",
                       votes: ($votes | tonumber),
                       comments: ($comments | tonumber),
                       topics: $topics
                   }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
            fi
        done
    fi
    
    # Fallback: Parse from HTML structure
    echo "$HTML" | grep -oP '<div[^>]*data-test="post-item"[^>]*>.*?</div>' 2>/dev/null | while read -r item; do
        NAME=$(echo "$item" | grep -oP '(?<=<h[23][^>]*data-test="post-name"[^>]*>)[^<]+' | head -1)
        DESC=$(echo "$item" | grep -oP '(?<=<p[^>]*>)[^<]+' | head -1)
        
        if [ -n "$NAME" ] && [ "$NAME" != "" ]; then
            jq --arg name "$NAME" \
               --arg desc "$DESC" \
               '.products += [{
                   name: $name,
                   description: $desc,
                   url: "",
                   category: "producthunt",
                   source: "producthunt"
               }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
        fi
    done
}

# Collect AI-focused products from Product Hunt
log "Collecting from Product Hunt..."

# Topics page for AI
collect_from_page "https://www.producthunt.com/topics/artificial-intelligence"

# Recent launches (last 7 days)
for day in 0 1 2 3 4 5 6; do
    DATE=$(date -d "$day days ago" +"%Y/%m/%d" 2>/dev/null || date -v-${day}d +"%Y/%m/%d" 2>/dev/null || echo "")
    if [ -n "$DATE" ]; then
        sleep 1
        collect_from_page "https://www.producthunt.com/$DATE"
    fi
done

# Filter for AI-related products
jq '[.products[] | select(
    (.topics | test("AI|artificial|machine learning|automation|chat|GPT|LLM"; "i")) or
    (.description | test("AI|artificial|machine learning|automation|chat|GPT|LLM"; "i")) or
    (.name | test("AI|GPT|Bot|Chat|Assistant|Intelligence"; "i"))
)] | {source: "producthunt", products: .}' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

# Deduplicate
jq '.products |= unique_by(.name | ascii_downcase)' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

# Sort by votes
jq '.products |= sort_by(.votes) | reverse' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

PRODUCT_COUNT=$(jq '.products | length' "$OUTPUT_FILE")
log "Collected $PRODUCT_COUNT AI products from Product Hunt"

exit 0
