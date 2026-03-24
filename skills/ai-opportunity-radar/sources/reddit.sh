#!/bin/bash
#
# Source: Reddit (r/SaaS, r/artificial)
# Coleta tendências, dores de usuários e discussões de produtos
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(dirname "$(ls -td /tmp/radar-*/ 2>/dev/null | head -1)")
OUTPUT_FILE="$TEMP_DIR/source-reddit.json"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

log() {
    echo "[reddit] $1"
}

# Initialize output
echo '{"source": "reddit", "products": []}' > "$OUTPUT_FILE"

collect_subreddit() {
    local subreddit="$1"
    local category="$2"
    
    log "Fetching r/$subreddit..."
    
    sleep 2
    
    # Reddit JSON API (add .json to any Reddit URL)
    JSON=$(curl -s -L \
        -H "User-Agent: $USER_AGENT" \
        --max-time 30 \
        "https://www.reddit.com/r/$subreddit/hot.json?limit=50" 2>/dev/null || echo "")
    
    if [ -z "$JSON" ]; then
        log "Warning: Empty response from r/$subreddit"
        return
    fi
    
    # Parse posts
    echo "$JSON" | jq -r '.data.children[].data' 2>/dev/null | jq -c 'select(.title != null)' | while read -r post; do
        TITLE=$(echo "$post" | jq -r '.title')
        SELFTEXT=$(echo "$post" | jq -r '.selftext')
        URL=$(echo "$post" | jq -r '.url')
        UPVOTES=$(echo "$post" | jq -r '.ups')
        COMMENTS=$(echo "$post" | jq -r '.num_comments')
        FLAIR=$(echo "$post" | jq -r '.link_flair_text // "discussion"')
        
        # Extract potential product names from title
        # Patterns: "I built X", "Launching X", "Show HN: X", "My SaaS X", etc.
        PRODUCT_NAME=""
        
        if echo "$TITLE" | grep -qiE '(built|made|created|launched|announcing|introducing|my (new )?(saas|app|tool|product|ai))'; then
            # Extract product name after keywords
            PRODUCT_NAME=$(echo "$TITLE" | sed -n 's/.*[Bb]uilt \{0,1\}\(.*\)/\1/p; 
                                                 s/.*[Mm]ade \{0,1\}\(.*\)/\1/p;
                                                 s/.*[Cc]reated \{0,1\}\(.*\)/\1/p;
                                                 s/.*[Ll]aunched \{0,1\}\(.*\)/\1/p;
                                                 s/.*[Aa]nnouncing \{0,1\}\(.*\)/\1/p;
                                                 s/.*[Ii]ntroducing \{0,1\}\(.*\)/\1/p;
                                                 s/.*[Mm]y [Ss][Aa][Aa][Ss] \{0,1\}\(.*\)/\1/p;
                                                 s/.*[Mm]y [Aa][Pp][Pp] \{0,1\}\(.*\)/\1/p;
                                                 s/.*[Ss]how [Hh][Nn]: \{0,1\}\(.*\)/\1/p' | head -1 | cut -c1-100)
        fi
        
        # If we found a product name or it's a high-engagement post about tools
        if [ -n "$PRODUCT_NAME" ] || ([ "$UPVOTES" -gt 50 ] && echo "$TITLE $SELFTEXT" | grep -qiE '(tool|app|software|platform|service|solution|product)'); then
            [ -z "$PRODUCT_NAME" ] && PRODUCT_NAME="$TITLE"
            
            # Truncate long names
            PRODUCT_NAME=$(echo "$PRODUCT_NAME" | cut -c1-100)
            
            DESC="$SELFTEXT"
            [ -z "$DESC" ] && DESC="$TITLE"
            DESC=$(echo "$DESC" | cut -c1-200)
            
            jq --arg name "$PRODUCT_NAME" \
               --arg desc "$DESC" \
               --arg url "$URL" \
               --arg votes "$UPVOTES" \
               --arg comments "$COMMENTS" \
               --arg flair "$FLAIR" \
               --arg cat "$category" \
               '.products += [{
                   name: $name,
                   description: $desc,
                   url: $url,
                   category: $cat,
                   source: "reddit",
                   reddit_upvotes: ($votes | tonumber),
                   reddit_comments: ($comments | tonumber),
                   reddit_flair: $flair
               }]' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
        fi
    done
}

# Collect from relevant subreddits
log "Collecting from Reddit..."

# SaaS discussions
collect_subreddit "SaaS" "saas"

# Artificial Intelligence
sleep 1
collect_subreddit "artificial" "artificial-intelligence"

# Startups
sleep 1
collect_subreddit "startups" "startups"

# SideProject
sleep 1
collect_subreddit "SideProject" "side-projects"

# Indiemakers
sleep 1
collect_subreddit "Indiemakers" "indie-makers"

# MachineLearning
sleep 1
collect_subreddit "MachineLearning" "machine-learning"

# Deduplicate
jq '.products |= unique_by(.name | ascii_downcase)' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

# Sort by upvotes
jq '.products |= sort_by(.reddit_upvotes) | reverse' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

PRODUCT_COUNT=$(jq '.products | length' "$OUTPUT_FILE")
log "Collected $PRODUCT_COUNT products from Reddit"

exit 0
