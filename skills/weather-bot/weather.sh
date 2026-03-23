#!/bin/bash
# Weather Bot Forecast Script
# Fetches weather data from Open-Meteo and outputs formatted forecast as JSON
#
# Usage: weather.sh <type> <lat> <lon> <location_name>
#   type: "today", "tomorrow", "3days", "7days"
#   lat: latitude (e.g., -23.55)
#   lon: longitude (e.g., -46.70)
#   location_name: human-readable location name
#
# Output format: JSON with "message" field containing the formatted forecast

# Configuration
TIMEZONE="America/Sao_Paulo"
START_HOUR=8
END_HOUR=18

# Parse command line arguments
FORECAST_TYPE="${1:-today}"
LATITUDE="${2:--23.55}"
LONGITUDE="${3:--46.70}"
LOCATION_NAME="${4:-São Paulo Zona Oeste}"

# Colors for terminal output (not used in output)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Error handling
error() {
    echo "{\"error\":\"$1\"}"
    exit 1
}

# Check required commands
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        error "curl is required but not installed"
    fi

    if ! command -v jq &> /dev/null; then
        USE_JQ=false
    else
        USE_JQ=true
    fi
}

# Get current date in Portuguese
get_date_pt() {
    local date_str="$1"
    TZ="${TIMEZONE}" date -d "$date_str" '+%A, %d/%m/%Y' | sed 's/Monday/Segunda-feira/;s/Tuesday/Terça-feira/;s/Wednesday/Quarta-feira/;s/Thursday/Quinta-feira/;s/Friday/Sexta-feira/;s/Saturday/Sábado/;s/Sunday/Domingo/'
}

# Get number of forecast days based on type
get_forecast_days() {
    local type="$1"
    case "$type" in
        today|tomorrow)
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
        today)
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

    TZ="${TIMEZONE}" date -d "+${offset} days" '+%Y-%m-%d'
}

# Get end date for filtering (for multi-day forecasts)
get_end_date() {
    local type="$1"
    case "$type" in
        today|tomorrow)
            get_target_date "$type"
            ;;
        3days|7days)
            get_target_date "$type"
            ;;
        *)
            TZ="${TIMEZONE}" date '+%Y-%m-%d'
            ;;
    esac
}

# Get weather emoji based on rain probability
get_weather_emoji() {
    local rain_prob=$1
    local rain_amount=$2

    # Convert to integer for comparison (bash doesn't handle floats)
    local rain_prob_int=${rain_prob%.*}
    local rain_amount_int=${rain_amount%.*}

    if [ "$rain_prob_int" -ge 70 ]; then
        echo "🌧️"
    elif [ "$rain_prob_int" -ge 40 ]; then
        echo "🌦️"
    elif [ "$rain_prob_int" -ge 20 ]; then
        echo "⛅"
    else
        if [ "$rain_amount_int" -gt 0 ]; then
            echo "🌦️"
        else
            echo "☀️"
        fi
    fi
}

# Fetch weather data from Open-Meteo
fetch_weather() {
    local forecast_days=$(get_forecast_days "$FORECAST_TYPE")
    local url="https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=temperature_2m,precipitation_probability,precipitation&forecast_days=${forecast_days}&timezone=${TIMEZONE}&models=best_match"

    local response
    response=$(curl -s --fail --max-time 30 "$url" 2>&1) || {
        error "Failed to fetch weather data: $response"
    }

    echo "$response"
}

# Parse and format weather data
format_weather_message() {
    local json="$1"

    local times=""
    local temperatures=""
    local rain_probs=""
    local rain_amounts=""

    # Try jq first, fallback to grep/sed if jq fails
    if [ "$USE_JQ" = true ]; then
        times=$(echo "$json" | jq -r '.hourly.time[]' 2>/dev/null)
        temperatures=$(echo "$json" | jq -r '.hourly.temperature_2m[]' 2>/dev/null)
        rain_probs=$(echo "$json" | jq -r '.hourly.precipitation_probability[]' 2>/dev/null)
        rain_amounts=$(echo "$json" | jq -r '.hourly.precipitation[]' 2>/dev/null)

        # If jq failed, fallback to grep/sed
        if [ -z "$times" ]; then
            echo "Warning: jq failed, falling back to grep/sed" >&2
            times=$(echo "$json" | grep -o '"time":"[^"]*"' | sed 's/"time":"//;s/"$//')
            temperatures=$(echo "$json" | grep -o '"temperature_2m":[0-9.-]*' | sed 's/"temperature_2m"://')
            rain_probs=$(echo "$json" | grep -o '"precipitation_probability":[0-9]*' | sed 's/"precipitation_probability"://')
            rain_amounts=$(echo "$json" | grep -o '"precipitation":[0-9.]*' | sed 's/"precipitation"://')
        fi
    else
        times=$(echo "$json" | grep -o '"time":"[^"]*"' | sed 's/"time":"//;s/"$//')
        temperatures=$(echo "$json" | grep -o '"temperature_2m":[0-9.-]*' | sed 's/"temperature_2m"://')
        rain_probs=$(echo "$json" | grep -o '"precipitation_probability":[0-9]*' | sed 's/"precipitation_probability"://')
        rain_amounts=$(echo "$json" | grep -o '"precipitation":[0-9.]*' | sed 's/"precipitation"://')
    fi

    if [ -z "$times" ]; then
        error "No weather data received from API"
    fi

    # Build message header based on type
    local header_title="Previsão do Tempo"
    case "$FORECAST_TYPE" in
        today)
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
    message+="───────────────\n\n"

    if [ "$FORECAST_TYPE" = "today" ] || [ "$FORECAST_TYPE" = "tomorrow" ]; then
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
    local today_date=$(TZ="${TIMEZONE}" date '+%Y-%m-%d')
    local current_hour=$(TZ="${TIMEZONE}" date '+%H' | sed 's/^0//')

    local start_date
    if [ "$FORECAST_TYPE" = "3days" ] || [ "$FORECAST_TYPE" = "7days" ]; then
        start_date="$today_date"
    else
        start_date=$(get_target_date "$FORECAST_TYPE")
    fi
    local end_date=$(get_end_date "$FORECAST_TYPE")

    local filter_current_hour=false
    local show_all_hours=false
    if [ "$FORECAST_TYPE" = "today" ]; then
        filter_current_hour=true
        show_all_hours=true
    fi

    # For "today" and "tomorrow", we already added the date header above,
    # so initialize last_displayed_date to prevent duplicate header
    local last_displayed_date=""
    if [ "$FORECAST_TYPE" = "today" ] || [ "$FORECAST_TYPE" = "tomorrow" ]; then
        last_displayed_date="$start_date"
    fi

    for i in "${!time_array[@]}"; do
        local time="${time_array[$i]}"
        local temp="${temp_array[$i]}"
        local rain_prob="${rain_prob_array[$i]}"
        local rain_amount="${rain_amount_array[$i]}"

        local date=$(echo "$time" | grep -oP '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
        local hour=$(echo "$time" | grep -oP 'T\K[0-9]{2}' | sed 's/^0//')

        local within_date_range=false
        if [[ "$date" > "$start_date" ]] || [ "$date" = "$start_date" ]; then
            if [[ "$date" < "$end_date" ]] || [ "$date" = "$end_date" ]; then
                within_date_range=true
            fi
        fi

        # Determine if this hour should be displayed
        local display_hour=false
        if [ "$show_all_hours" = true ] && [ "$date" = "$today_date" ]; then
            # For today, show all hours from current_hour onwards
            if [ "$hour" -ge "$current_hour" ]; then
                display_hour=true
            fi
        else
            # For other days, show hours 8-18
            if [ "$hour" -ge "$START_HOUR" ] && [ "$hour" -le "$END_HOUR" ]; then
                display_hour=true
            fi
        fi

        if [ "$within_date_range" = true ] && [ -n "$hour" ] && [ "$display_hour" = true ]; then

            if [ "$date" != "$last_displayed_date" ]; then
                message+="\n📅 $(get_date_pt "${date}")\n"
                last_displayed_date="$date"
            fi

            local hour_formatted=$(printf "%02d" "$hour")
            local emoji=$(get_weather_emoji "$rain_prob" "$rain_amount")
            local rain_amount_rounded=$(printf "%.1f" "$rain_amount")

            message+="${emoji} *${hour_formatted}h00* - *${temp}°C*\n"
            message+="   💧 Chuva: ${rain_prob}% • ${rain_amount_rounded}mm\n\n"
            has_data=true
        fi
    done

    if [ "$has_data" = false ]; then
        error "No weather data available for the specified time range"
    fi

    message+="\n───────────────\n"
    message+="✨ Oferecido por Clínica Estética My Shape - Vila Romana"

    echo -e "$message"
}

# Main function
main() {
    check_dependencies

    local weather_json
    weather_json=$(fetch_weather)

    local formatted_message
    formatted_message=$(format_weather_message "$weather_json")

    # Output as JSON
    local escaped_message=$(echo "$formatted_message" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\\/\\\\/g; s/"/\\"/g')
    echo "{\"message\":\"${escaped_message}\"}"
}

main
