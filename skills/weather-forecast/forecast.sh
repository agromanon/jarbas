#!/bin/bash
# Weather Forecast Script for São Paulo Zona Oeste
# Fetches weather data from Open-Meteo and sends to Telegram
#
# Usage: forecast.sh [type]
#   type: "today" (default), "tomorrow", "3days", "7days"
#   type: "morning" - 8h to 12h (for manual/cron use)
#   type: "afternoon" - 13h to 18h (for manual/cron use)
#
# Output format: JSON with "message" field containing the formatted forecast

# Configuration
LATITUDE="-23.55"
LONGITUDE="-46.70"
LOCATION_NAME="São Paulo Zona Oeste"
TIMEZONE="America/Sao_Paulo"
START_HOUR=8
END_HOUR=18

# Parse command line arguments
FORECAST_TYPE="${1:-today}"
OUTPUT_JSON="${2:-false}"

# Telegram configuration
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID}"

# Colors for terminal output (not used in Telegram message)
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

    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}Warning: jq is not installed. Using basic JSON parsing.${NC}"
        USE_JQ=false
    else
        USE_JQ=true
    fi
}

# Check environment variables
check_env_vars() {
    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        error "TELEGRAM_BOT_TOKEN environment variable is not set"
    fi

    if [ -z "$TELEGRAM_CHAT_ID" ]; then
        error "TELEGRAM_CHAT_ID environment variable is not set"
    fi
}

# Get current date in Portuguese
get_date_pt() {
    local date_str="$1"
    date -d "$date_str" '+%A, %d/%m/%Y' | sed 's/Monday/Segunda-feira/;s/Tuesday/Terça-feira/;s/Wednesday/Quarta-feira/;s/Thursday/Quinta-feira/;s/Friday/Sexta-feira/;s/Saturday/Sábado/;s/Sunday/Domingo/'
}

# Get number of forecast days based on type
get_forecast_days() {
    local type="$1"
    case "$type" in
        today|tomorrow|morning|afternoon)
            echo "2"
            ;;
        3days)
            echo "4"
            ;;
        7days)
            echo "8"
            ;;
        *)
            echo "2"
            ;;
    esac
}

# Get target date for filtering
get_target_date() {
    local type="$1"
    local offset=0

    case "$type" in
        today|morning|afternoon)
            offset=0
            ;;
        tomorrow)
            offset=1
            ;;
        3days)
            offset=2
            ;;
        7days)
            offset=6
            ;;
    esac

    date -d "+${offset} days" '+%Y-%m-%d'
}

# Get end date for filtering (for multi-day forecasts)
get_end_date() {
    local type="$1"
    case "$type" in
        today|tomorrow|morning|afternoon)
            get_target_date "$type"
            ;;
        3days|7days)
            get_target_date "$type"
            ;;
        *)
            date '+%Y-%m-%d'
            ;;
    esac
}

# Get weather emoji based on rain probability
get_weather_emoji() {
    local rain_prob=$1
    local rain_amount=$2

    if [ "$rain_prob" -ge 70 ]; then
        echo "🌧️"
    elif [ "$rain_prob" -ge 40 ]; then
        echo "🌦️"
    elif [ "$rain_prob" -ge 20 ]; then
        echo "⛅"
    else
        # Check for rain amount even if probability is low
        if [ "$rain_amount" -gt 0 ]; then
            echo "🌦️"
        else
            echo "☀️"
        fi
    fi
}

# Fetch weather data from Open-Meteo
fetch_weather() {
    local forecast_days=$(get_forecast_days "$FORECAST_TYPE")
    local url="https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=temperature_2m,precipitation_probability,precipitation&forecast_days=${forecast_days}&models=best_match&timezone=${TIMEZONE}"

    local response
    response=$(curl -s --fail --max-time 30 "$url" 2>&1) || {
        error "Failed to fetch weather data: $response"
    }

    echo "$response"
}

# Parse and format weather data
format_weather_message() {
    local json="$1"

    # Check if jq is available
    if [ "$USE_JQ" = true ]; then
        # Extract hourly data using jq
        local times=$(echo "$json" | jq -r '.hourly.time[]')
        local temperatures=$(echo "$json" | jq -r '.hourly.temperature_2m[]')
        local rain_probs=$(echo "$json" | jq -r '.hourly.precipitation_probability[]')
        local rain_amounts=$(echo "$json" | jq -r '.hourly.precipitation[]')
    else
        # Basic JSON parsing (fallback)
        local times=$(echo "$json" | grep -o '"time":"[^"]*"' | sed 's/"time":"//;s/"$//')
        local temperatures=$(echo "$json" | grep -o '"temperature_2m":[0-9.-]*' | sed 's/"temperature_2m"://')
        local rain_probs=$(echo "$json" | grep -o '"precipitation_probability":[0-9]*' | sed 's/"precipitation_probability"://')
        local rain_amounts=$(echo "$json" | grep -o '"precipitation":[0-9.]*' | sed 's/"precipitation"://')
    fi

    if [ -z "$times" ]; then
        error "No weather data received from API"
    fi

    # Build message header based on type
    local header_title="Previsão do Tempo"
    case "$FORECAST_TYPE" in
        today|morning|afternoon)
            header_title="Previsão do Tempo - Hoje"
            ;;
        tomorrow)
            header_title="Previsão do Tempo - Amanhã"
            ;;
        3days)
            header_title="Previsão do Tempo - Próximos 3 dias"
            ;;
        7days)
            header_title="Previsão do Tempo - Próximos 7 dias"
            ;;
    esac

    # Build message
    local message="🌤️ ${header_title} - ${LOCATION_NAME}\n"
    message+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"

    # For multi-day forecasts, we'll add dates inline
    # For single-day forecasts, add the date at the top
    if [ "$FORECAST_TYPE" = "today" ] || [ "$FORECAST_TYPE" = "tomorrow" ] || [ "$FORECAST_TYPE" = "morning" ] || [ "$FORECAST_TYPE" = "afternoon" ]; then
        local target_date=$(get_target_date "$FORECAST_TYPE")
        message+="📅 $(get_date_pt "${target_date}")\n\n"
    fi

    # Parse hourly data
    local count=0
    local has_data=false

    # Convert to arrays
    local time_array=()
    local temp_array=()
    local rain_prob_array=()
    local rain_amount_array=()

    while IFS= read -r time; do
        time_array+=("$time")
    done <<< "$times"

    while IFS= read -r temp; do
        temp_array+=("$temp")
    done <<< "$temperatures"

    while IFS= read -r rain_prob; do
        rain_prob_array+=("$rain_prob")
    done <<< "$rain_probs"

    while IFS= read -r rain_amount; do
        rain_amount_array+=("$rain_amount")
    done <<< "$rain_amounts"

    # Get date filtering parameters
    local today_date=$(date '+%Y-%m-%d')
    local current_hour=$(TZ="${TIMEZONE}" date '+%H' | sed 's/^0//')

    # For multi-day forecasts, start from today
    local start_date
    if [ "$FORECAST_TYPE" = "3days" ] || [ "$FORECAST_TYPE" = "7days" ]; then
        start_date="$today_date"
    else
        start_date=$(get_target_date "$FORECAST_TYPE")
    fi
    local end_date=$(get_end_date "$FORECAST_TYPE")

    # For today/morning/afternoon, filter by current hour
    local filter_current_hour=false
    if [ "$FORECAST_TYPE" = "today" ] || [ "$FORECAST_TYPE" = "morning" ] || [ "$FORECAST_TYPE" = "afternoon" ]; then
        filter_current_hour=true
    fi

    # Adjust hour range for morning/afternoon
    local start_hour_filter=$START_HOUR
    local end_hour_filter=$END_HOUR
    if [ "$FORECAST_TYPE" = "morning" ]; then
        start_hour_filter=8
        end_hour_filter=12
    elif [ "$FORECAST_TYPE" = "afternoon" ]; then
        start_hour_filter=13
        end_hour_filter=18
    fi

    # Track last displayed date for multi-day forecasts
    local last_displayed_date=""

    # Loop through hours and filter
    for i in "${!time_array[@]}"; do
        local time="${time_array[$i]}"
        local temp="${temp_array[$i]}"
        local rain_prob="${rain_prob_array[$i]}"
        local rain_amount="${rain_amount_array[$i]}"

        # Extract date and hour from time (format: 2026-03-20T08:00)
        local date=$(echo "$time" | grep -oP '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        local hour=$(echo "$time" | grep -oP 'T\K[0-9]{2}' | sed 's/^0//')

        # Check if date is within range
        local within_date_range=false
        if [[ "$date" > "$start_date" ]] || [ "$date" = "$start_date" ]; then
            if [[ "$date" < "$end_date" ]] || [ "$date" = "$end_date" ]; then
                within_date_range=true
            fi
        fi

        # Only include if within date range and within hour range
        if [ "$within_date_range" = true ] && [ -n "$hour" ] && [ "$hour" -ge "$start_hour_filter" ] && [ "$hour" -le "$end_hour_filter" ]; then
            # For today, also filter by current hour
            if [ "$filter_current_hour" = true ] && [ "$date" = "$today_date" ] && [ "$hour" -lt "$current_hour" ]; then
                continue
            fi

            # Add date separator for multi-day forecasts
            if [ "$date" != "$last_displayed_date" ] && [ "$date" != "$start_date" ]; then
                message+="\n📅 $(get_date_pt "${date}")\n"
                last_displayed_date="$date"
            fi

            # Format hour with leading zero
            local hour_formatted=$(printf "%02d" "$hour")

            # Get weather emoji
            local emoji=$(get_weather_emoji "$rain_prob" "$rain_amount")

            # Round rain amount
            local rain_amount_rounded=$(printf "%.1f" "$rain_amount")

            # Add to message
            message+="${emoji} ${hour_formatted}h00 - ${temp}°C Chuva: ${rain_prob}% 💧${rain_amount_rounded}mm\n"
            has_data=true
        fi
    done

    if [ "$has_data" = false ]; then
        error "No weather data available for the specified time range"
    fi

    message+="\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    message+="\n⏰ $(date '+%H:%M' -d '+3 hours' 2>/dev/null || date '+%H:%M')"

    echo -e "$message"
}

# Send message to Telegram
send_to_telegram() {
    local message="$1"

    # If OUTPUT_JSON is true, output JSON and don't send
    if [ "$OUTPUT_JSON" = "true" ]; then
        # Escape special characters for JSON
        # Convert newlines to \n, escape backslashes and quotes
        local escaped_message=$(echo "$message" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g; s/"/\\"/g')
        echo "{\"message\":\"${escaped_message}\"}"
        return 0
    fi

    echo -e "${BLUE}Sending message to Telegram...${NC}"

    # Escape special characters for JSON
    local escaped_message=$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')

    # Prepare API request
    local payload="{\"chat_id\":\"${TELEGRAM_CHAT_ID}\",\"text\":\"${escaped_message}\",\"parse_mode\":\"Markdown\"}"

    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" 2>&1)

    # Check response
    if echo "$response" | grep -q '"ok":true'; then
        echo -e "${GREEN}✓ Message sent successfully to Telegram${NC}"
        return 0
    else
        error "Failed to send message to Telegram: $response"
    fi
}

# Main function
main() {
    # Don't print logs if outputting JSON
    if [ "$OUTPUT_JSON" = "false" ]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}  Weather Forecast Script${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    fi

    check_dependencies

    # Only check env vars if not outputting JSON (for use by Telegram handler)
    if [ "$OUTPUT_JSON" = "false" ]; then
        check_env_vars
        echo -e "${BLUE}Fetching weather data for ${LOCATION_NAME} (${FORECAST_TYPE})...${NC}"
    fi

    # Fetch weather data
    local weather_json
    weather_json=$(fetch_weather)

    # Format message
    local formatted_message
    formatted_message=$(format_weather_message "$weather_json")

    # Output message if not JSON mode
    if [ "$OUTPUT_JSON" = "false" ]; then
        echo ""
        echo -e "${BLUE}Formatted message:${NC}"
        echo ""
        echo -e "$formatted_message"
        echo ""
    fi

    # Send to Telegram (or output JSON)
    send_to_telegram "$formatted_message"

    if [ "$OUTPUT_JSON" = "false" ]; then
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}  ✓ Weather forecast sent successfully${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
}

# Run main function
main
