#!/bin/bash
# Daily AI/Tech News Script
# Fetches top stories from Hacker News and summarizes AI/tech-related content

# Configuration
HackerNews_API_BASE="https://hacker-news.firebaseio.com/v0"
MAX_STORIES=50
TOP_N=3
KEYWORDS="AI|artificial intelligence|machine learning|ML|deep learning|neural|GPT|LLM|ChatGPT|Claude|tech|technology|programming|developer|software|engineering|data science|blockchain|crypto|cybersecurity"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Error handling
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Check required commands
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        error "curl is required but not installed"
    fi
}

# Fetch data from API with error handling
fetch_api() {
    local url="$1"
    local response
    response=$(curl -s --fail --max-time 30 "$url" 2>&1) || {
        error "Failed to fetch $url: $response"
    }
    echo "$response"
}

# Check if string contains any keywords
contains_keyword() {
    local text="$1"
    local text_lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')
    local keywords_lower=$(echo "$KEYWORDS" | tr '[:upper:]' '[:lower:]')

    if echo "$text_lower" | grep -qiE "$keywords_lower"; then
        return 0
    else
        return 1
    fi
}

# Get current date
get_date() {
    date '+%Y-%m-%d'
}

# Main function
main() {
    check_dependencies

    echo -e "${BLUE}Fetching latest AI/Tech news from Hacker News...${NC}"
    echo ""

    # Get top story IDs
    echo "Fetching top story IDs..."
    local story_ids
    story_ids=$(fetch_api "${HackerNews_API_BASE}/topstories.json")

    if [ -z "$story_ids" ]; then
        error "No story IDs received"
    fi

    # Extract first N story IDs (remove brackets, split by comma)
    local top_ids
    top_ids=$(echo "$story_ids" | sed 's/\[//;s/\]//' | tr ',' '\n' | head -n "$MAX_STORIES" | tr '\n' ',' | sed 's/,$//')

    if [ -z "$top_ids" ]; then
        error "Failed to extract story IDs"
    fi

    echo "Analyzing $MAX_STORIES stories..."
    echo ""

    # Arrays to store relevant stories
    declare -a titles
    declare -a urls
    declare -a scores
    declare -a comment_counts
    declare -a story_ids_array

    # Fetch details for each story
    local total_analyzed=0
    local relevant_count=0

    # Convert comma-separated IDs to newline-separated and iterate
    while IFS= read -r story_id; do
        [ -z "$story_id" ] && continue

        ((total_analyzed++))

        # Fetch story details
        local story_json
        story_json=$(fetch_api "${HackerNews_API_BASE}/item/${story_id}.json")

        # Extract fields using grep and sed (JSON parsing without jq)
        local title=$(echo "$story_json" | grep -o '"title":"[^"]*"' | sed 's/"title":"//;s/"$//' 2>/dev/null || echo "")
        local url=$(echo "$story_json" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"$//' 2>/dev/null || echo "")
        local score=$(echo "$story_json" | grep -o '"score":[0-9]*' | sed 's/"score"://' 2>/dev/null || echo "0")
        local descendants=$(echo "$story_json" | grep -o '"descendants":[0-9]*' | sed 's/"descendants"://' 2>/dev/null || echo "0")

        # Check if story is relevant
        if [ -n "$title" ]; then
            if contains_keyword "$title"; then
                titles+=("$title")
                urls+=("$url")
                scores+=("$score")
                comment_counts+=("$descendants")
                story_ids_array+=("$story_id")
                ((relevant_count++))
            fi
        fi

        # Progress indicator
        if [ $((total_analyzed % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done <<< "$(echo "$top_ids" | tr ',' '\n')"

    echo ""
    echo ""

    if [ $relevant_count -eq 0 ]; then
        echo -e "${YELLOW}No AI/tech related stories found in the top $MAX_STORIES stories.${NC}"
        echo ""
        exit 0
    fi

    # Sort stories by score (bubble sort for compatibility)
    local n=$relevant_count
    for ((i=0; i<n; i++)); do
        for ((j=0; j<n-i-1; j++)); do
            if [ "${scores[$j]}" -lt "${scores[$((j+1))]}" ]; then
                # Swap
                temp="${titles[$j]}"; titles[$j]="${titles[$((j+1))]}"; titles[$((j+1))]=$temp
                temp="${urls[$j]}"; urls[$j]="${urls[$((j+1))]}"; urls[$((j+1))]=$temp
                temp="${scores[$j]}"; scores[$j]="${scores[$((j+1))]}"; scores[$((j+1))]=$temp
                temp="${comment_counts[$j]}"; comment_counts[$j]="${comment_counts[$((j+1))]}"; comment_counts[$((j+1))]=$temp
                temp="${story_ids_array[$j]}"; story_ids_array[$j]="${story_ids_array[$((j+1))]}"; story_ids_array[$((j+1))]=$temp
            fi
        done
    done

    # Output top N stories
    local display_count=$((relevant_count < TOP_N ? relevant_count : TOP_N))
    local current_date=$(get_date)

    echo -e "${GREEN}# Top AI/Tech News - $current_date${NC}"
    echo ""

    for ((i=0; i<display_count; i++)); do
        local num=$((i+1))
        local story_url="${urls[$i]}"

        # If URL is empty, use Hacker News item URL
        if [ -z "$story_url" ]; then
            story_url="https://news.ycombinator.com/item?id=${story_ids_array[$i]}"
        fi

        echo -e "${YELLOW}## $num. [${titles[$i]}]($story_url)${NC}"
        echo "Score: ${scores[$i]} points"
        echo "Comments: ${comment_counts[$i]}"
        echo ""
    done

    echo -e "${BLUE}---${NC}"
    echo -e "${BLUE}Fetched $MAX_STORIES stories, found $relevant_count AI/tech related stories${NC}"
}

# Run main function
main
