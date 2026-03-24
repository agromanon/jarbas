#!/bin/bash
#
# Source: Product Hunt - B2C Consumer Focus
# Coleta produtos de IA para CONSUMIDOR (não Developer Tools)
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

OUTPUT_FILE="$TEMP_DIR/source-producthunt-b2c.json"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

log() {
    echo "[producthunt-b2c] $1"
}

# Initialize output
echo '{"source": "producthunt-b2c", "products": []}' > "$OUTPUT_FILE"

# ============================================
# B2C TOPICS TO SCRAPE
# Consumer-facing, NOT developer tools
# ============================================

B2C_TOPICS=(
    "artificial-intelligence"
    "productivity"
    "social-media"
    "design-tools"
    "video"
    "photo-editing"
    "writing"
    "education"
    "lifestyle"
    "health-and-fitness"
    "music"
    "travel"
    "finance"
    "job"
)

# Topics to EXPLICITLY SKIP
EXCLUDED_TOPICS=(
    "developer-tools"
    "api"
    "tech"
    "cloud"
    "database"
    "analytics"
    "security"
    "devops"
    "infrastructure"
)

collect_topic() {
    local topic="$1"
    local url="https://www.producthunt.com/topics/${topic}"
    
    log "Fetching topic: $topic"
    
    sleep 2
    
    HTML=$(curl -s -L \
        -H "User-Agent: $USER_AGENT" \
        -H "Accept: text/html,application/xhtml+xml" \
        --max-time 30 \
        "$url" 2>/dev/null || echo "")
    
    if [ -z "$HTML" ]; then
        log "Warning: Empty response for $topic"
        return
    fi
    
    # Product Hunt uses Next.js with __NEXT_DATA__
    NEXT_DATA=$(echo "$HTML" | grep -oP '(?<=<script id="__NEXT_DATA__" type="application/json">).*?(?=</script>)' 2>/dev/null | head -1 || echo "")
    
    if [ -n "$NEXT_DATA" ]; then
        # Parse products from Next.js data
        echo "$NEXT_DATA" | jq -r '
            .props.pageProps.topics[0].posts[]? //
            .props.pageProps.posts[]? //
            .props.initialProps.posts[]? //
            empty
        ' 2>/dev/null | while read -r post; do
            NAME=$(echo "$post" | jq -r '.name // empty' 2>/dev/null)
            DESC=$(echo "$post" | jq -r '.tagline // .description // empty' 2>/dev/null)
            VOTES=$(echo "$post" | jq -r '.votesCount // .votes // 0' 2>/dev/null)
            TOPICS=$(echo "$post" | jq -r '[.topics[]?.name // empty] | join(", ") // empty' 2>/dev/null)
            
            # Only include if has decent votes (validation)
            if [ -n "$NAME" ] && [ "$VOTES" -gt 20 ] 2>/dev/null; then
                # Check if it's B2C
                IS_B2C=true
                
                # Check topics for excluded
                for ex_topic in "${EXCLUDED_TOPICS[@]}"; do
                    if echo "$TOPICS" | grep -qi "$ex_topic"; then
                        IS_B2C=false
                        break
                    fi
                done
                
                # Check name/desc for excluded patterns
                if [ "$IS_B2C" = true ]; then
                    if echo "$NAME $DESC" | grep -qiE "api|sdk|framework|developer tool|infrastructure|enterprise|b2b platform"; then
                        IS_B2C=false
                    fi
                fi
                
                # Check for AI relevance
                IS_AI=false
                if echo "$NAME $DESC $TOPICS" | grep -qiE "ai|artificial intelligence|machine learning|gpt|chat|llm|automation|smart|intelligent"; then
                    IS_AI=true
                fi
                
                if [ "$IS_B2C" = true ] && [ "$IS_AI" = true ]; then
                    jq --arg name "$NAME" \
                       --arg desc "$DESC" \
                       --arg votes "$VOTES" \
                       --arg topics "$TOPICS" \
                       --arg cat "$topic" \
                       '.products += [{
                           name: $name,
                           description: $desc,
                           url: "",
                           category: $cat,
                           source: "producthunt-b2c",
                           votes: ($votes | tonumber),
                           topics: $topics
                       }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
                fi
            fi
        done
    fi
}

collect_date() {
    local date_path="$1"
    local url="https://www.producthunt.com/${date_path}"
    
    log "Fetching date: $date_path"
    
    sleep 1
    
    HTML=$(curl -s -L \
        -H "User-Agent: $USER_AGENT" \
        --max-time 30 \
        "$url" 2>/dev/null || echo "")
    
    if [ -z "$HTML" ]; then
        return
    fi
    
    NEXT_DATA=$(echo "$HTML" | grep -oP '(?<=<script id="__NEXT_DATA__" type="application/json">).*?(?=</script>)' 2>/dev/null | head -1 || echo "")
    
    if [ -n "$NEXT_DATA" ]; then
        echo "$NEXT_DATA" | jq -r '.props.pageProps.posts[]? // empty' 2>/dev/null | while read -r post; do
            NAME=$(echo "$post" | jq -r '.name // empty' 2>/dev/null)
            DESC=$(echo "$post" | jq -r '.tagline // empty' 2>/dev/null)
            VOTES=$(echo "$post" | jq -r '.votesCount // 0' 2>/dev/null)
            TOPICS=$(echo "$post" | jq -r '[.topics[]?.name // empty] | join(", ") // empty' 2>/dev/null)
            
            if [ -n "$NAME" ] && [ "$VOTES" -gt 50 ] 2>/dev/null; then
                # Check for AI + B2C
                IS_AI=false
                IS_B2C=true
                
                if echo "$NAME $DESC $TOPICS" | grep -qiE "ai|artificial|gpt|chat|llm|automation|smart"; then
                    IS_AI=true
                fi
                
                for ex_topic in "${EXCLUDED_TOPICS[@]}"; do
                    if echo "$TOPICS" | grep -qi "$ex_topic"; then
                        IS_B2C=false
                        break
                    fi
                done
                
                if [ "$IS_B2C" = true ] && [ "$IS_AI" = true ]; then
                    jq --arg name "$NAME" \
                       --arg desc "$DESC" \
                       --arg votes "$VOTES" \
                       --arg topics "$TOPICS" \
                       --arg cat "daily" \
                       '.products += [{
                           name: $name,
                           description: $desc,
                           url: "",
                           category: $cat,
                           source: "producthunt-b2c",
                           votes: ($votes | tonumber),
                           topics: $topics
                       }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
                fi
            fi
        done
    fi
}

# ============================================
# MAIN COLLECTION
# ============================================

log "Collecting B2C AI products from Product Hunt..."

# Collect from B2C topics
for topic in "${B2C_TOPICS[@]}"; do
    collect_topic "$topic"
    sleep 1
done

# Collect from last 3 days (for recent launches)
for day in 0 1 2; do
    DATE=$(date -d "$day days ago" +"%Y/%m/%d" 2>/dev/null || date -v-${day}d +"%Y/%m/%d" 2>/dev/null || echo "")
    if [ -n "$DATE" ]; then
        collect_date "$DATE"
        sleep 1
    fi
done

# ============================================
# DEDUPLICATION
# ============================================

# Remove duplicates
jq '.products |= unique_by(.name | ascii_downcase)' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

# Sort by votes
jq '.products |= sort_by(.votes) | reverse' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

# Limit to top 50
jq '.products |= .[0:50]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

PRODUCT_COUNT=$(jq '.products | length' "$OUTPUT_FILE")
log "Collected $PRODUCT_COUNT B2C AI products from Product Hunt"

exit 0
