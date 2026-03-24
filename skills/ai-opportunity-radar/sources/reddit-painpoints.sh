#!/bin/bash
#
# Source: Reddit - Real Pain Points
# Coleta dores reais de usuários (não promoção de produtos)
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

OUTPUT_FILE="$TEMP_DIR/source-reddit-painpoints.json"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

log() {
    echo "[reddit-painpoints] $1"
}

# Initialize output
echo '{"source": "reddit-painpoints", "products": []}' > "$OUTPUT_FILE"

# ============================================
# SUBREDDITS FOR REAL PAIN POINTS
# Focus on "I wish there was a tool for..." type posts
# ============================================

PAIN_SUBREDDITS=(
    "NoStupidQuestions"
    "TooAfraidToAsk"
    "productivity"
    "college"
    "GetStudying"
    "Entrepreneur"
    "smallbusiness"
    "SideProject"
    "creators"
    "NewTubers"
    "Instagram"
    "TikTok"
    "socialmedia"
    "resume"
    "jobs"
    "careerguidance"
    "personalfinance"
    "fitness"
    "loseit"
    "travel"
    "parenting"
    "wedding"
)

collect_painpoints() {
    local subreddit="$1"
    local category="$2"
    
    log "Fetching r/$subreddit for pain points..."
    
    sleep 2
    
    # Reddit JSON API
    JSON=$(curl -s -L \
        -H "User-Agent: $USER_AGENT" \
        --max-time 30 \
        "https://www.reddit.com/r/$subreddit/hot.json?limit=50" 2>/dev/null || echo "")
    
    if [ -z "$JSON" ]; then
        log "Warning: Empty response from r/$subreddit"
        return
    fi
    
    # Parse posts looking for pain points
    echo "$JSON" | jq -r '.data.children[].data' 2>/dev/null | jq -c 'select(.title != null)' | while read -r post; do
        TITLE=$(echo "$post" | jq -r '.title')
        SELFTEXT=$(echo "$post" | jq -r '.selftext' | head -c 500)
        UPVOTES=$(echo "$post" | jq -r '.ups')
        URL=$(echo "$post" | jq -r '.url')
        
        # Look for pain point patterns
        # "I wish there was...", "Does anyone know a tool...", "How do I...", "Is there an app..."
        IS_PAIN_POINT=false
        PAIN_TYPE=""
        
        if echo "$TITLE" | grep -qiE "i wish there (was|were)|wish there (was|were) a tool|need a tool|looking for a tool|anyone know (of )?a (tool|app|website)"; then
            IS_PAIN_POINT=true
            PAIN_TYPE="tool_wish"
        elif echo "$TITLE" | grep -qiE "how do (i |you )|how can i|best way to|easiest way to|is there (an? |any )?(easy|simple|quick|automated)"; then
            IS_PAIN_POINT=true
            PAIN_TYPE="how_to"
        elif echo "$TITLE" | grep -qiE "struggling with|hate having to|tired of|annoying when|frustrated by|sick of"; then
            IS_PAIN_POINT=true
            PAIN_TYPE="frustration"
        elif echo "$TITLE" | grep -qiE "does anyone (else )?(have|use|know)|why (is|does|dont|cant)"; then
            IS_PAIN_POINT=true
            PAIN_TYPE="question"
        fi
        
        # Only include high-engagement pain points (validation)
        if [ "$IS_PAIN_POINT" = true ] && [ "$UPVOTES" -gt 10 ] 2>/dev/null; then
            # Extract what the pain point is about
            PAIN_SUMMARY="$TITLE"
            
            # Try to identify category from content
            CONTENT_CAT="$category"
            if echo "$TITLE $SELFTEXT" | grep -qiE "instagram|tiktok|social media|content|post|follower"; then
                CONTENT_CAT="social-media"
            elif echo "$TITLE $SELFTEXT" | grep -qiE "study|homework|exam|college|school|learn"; then
                CONTENT_CAT="education"
            elif echo "$TITLE $SELFTEXT" | grep -qiE "resume|cv|job|interview|career"; then
                CONTENT_CAT="career"
            elif echo "$TITLE $SELFTEXT" | grep -qiE "diet|fitness|workout|weight|exercise"; then
                CONTENT_CAT="health-fitness"
            elif echo "$TITLE $SELFTEXT" | grep -qiE "money|budget|finance|save|spend"; then
                CONTENT_CAT="personal-finance"
            elif echo "$TITLE $SELFTEXT" | grep -qiE "business|customer|client|sell"; then
                CONTENT_CAT="small-business"
            elif echo "$TITLE $SELFTEXT" | grep -qiE "video|edit|thumbnail|youtube|channel"; then
                CONTENT_CAT="content-creation"
            fi
            
            # Create "opportunity" from pain point
            # The idea is: "AI tool to solve [pain point]"
            IDEA_NAME="AI tool for: $(echo "$TITLE" | cut -c1-60)"
            IDEA_DESC="Pain point from Reddit: $TITLE. Upvotes: $UPVOTES. Self-text: $SELFTEXT"
            
            jq --arg name "$IDEA_NAME" \
               --arg desc "$IDEA_DESC" \
               --arg url "$URL" \
               --arg votes "$UPVOTES" \
               --arg pain_type "$PAIN_TYPE" \
               --arg cat "$CONTENT_CAT" \
               --arg subreddit "$subreddit" \
               '.products += [{
                   name: $name,
                   description: $desc,
                   url: $url,
                   category: $cat,
                   source: "reddit-painpoints",
                   reddit_upvotes: ($votes | tonumber),
                   pain_type: $pain_type,
                   subreddit: $subreddit
               }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
        fi
    done
}

# Also look at specific search queries for pain points
search_reddit_painpoints() {
    local query="$1"
    local category="$2"
    
    log "Searching Reddit for: $query"
    
    sleep 2
    
    # Reddit search API
    ENCODED_QUERY=$(echo "$query" | sed 's/ /%20/g')
    JSON=$(curl -s -L \
        -H "User-Agent: $USER_AGENT" \
        --max-time 30 \
        "https://www.reddit.com/search.json?q=${ENCODED_QUERY}&sort=relevance&t=week&limit=25" 2>/dev/null || echo "")
    
    if [ -z "$JSON" ]; then
        return
    fi
    
    echo "$JSON" | jq -r '.data.children[].data' 2>/dev/null | jq -c 'select(.title != null)' | while read -r post; do
        TITLE=$(echo "$post" | jq -r '.title')
        SELFTEXT=$(echo "$post" | jq -r '.selftext' | head -c 300)
        UPVOTES=$(echo "$post" | jq -r '.ups')
        URL=$(echo "$post" | jq -r '.url')
        SUBREDDIT=$(echo "$post" | jq -r '.subreddit')
        
        if [ "$UPVOTES" -gt 5 ] 2>/dev/null; then
            IDEA_NAME="Pain: $(echo "$TITLE" | cut -c1-50)"
            IDEA_DESC="Reddit search '$query': $TITLE. Upvotes: $UPVOTES. r/$SUBREDDIT"
            
            jq --arg name "$IDEA_NAME" \
               --arg desc "$IDEA_DESC" \
               --arg url "$URL" \
               --arg votes "$UPVOTES" \
               --arg cat "$category" \
               --arg subreddit "$SUBREDDIT" \
               '.products += [{
                   name: $name,
                   description: $desc,
                   url: $url,
                   category: $cat,
                   source: "reddit-search",
                   reddit_upvotes: ($votes | tonumber),
                   subreddit: $subreddit
               }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
        fi
    done
}

# ============================================
# MAIN COLLECTION
# ============================================

log "Collecting pain points from Reddit..."

# Collect from subreddits
for subreddit in "${PAIN_SUBREDDITS[@]}"; do
    collect_painpoints "$subreddit" "general"
    sleep 1
done

# Search for specific pain point patterns
SEARCH_QUERIES=(
    '"I wish there was a tool"'
    '"Does anyone know a tool"'
    '"Is there an AI that"'
    '"need an app for"'
    '"automate this"'
    '"tired of manually"'
)

for query in "${SEARCH_QUERIES[@]}"; do
    search_reddit_painpoints "$query" "pain-point-search"
    sleep 1
done

# ============================================
# DEDUPLICATION
# ============================================

# Remove duplicates
jq '.products |= unique_by(.name | ascii_downcase)' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

# Sort by upvotes
jq '.products |= sort_by(.reddit_upvotes) | reverse' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

# Limit to top 30
jq '.products |= .[0:30]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

PRODUCT_COUNT=$(jq '.products | length' "$OUTPUT_FILE")
log "Collected $PRODUCT_COUNT pain points from Reddit"

exit 0
