#!/bin/bash
# Initialize Weather Bot Data Files
# Creates default data files if they don't exist

set -e

# Configuration - use /app/data when running inside Docker, /job/data for local
if [ -d "/app/data" ]; then
    DATA_DIR="/app/data"
else
    DATA_DIR="/job/data"
fi

# Get admin ID from environment or use default
ADMIN_ID="${WEATHER_BOT_ADMIN_ID:-5121600266}"

echo "Initializing weather bot data in ${DATA_DIR}..."

# Ensure data directory exists
mkdir -p "${DATA_DIR}"

# Initialize allowed-users.json if it doesn't exist
ALLOWED_USERS_FILE="${DATA_DIR}/allowed-users.json"
if [ ! -f "$ALLOWED_USERS_FILE" ]; then
    echo "Creating ${ALLOWED_USERS_FILE}..."
    cat > "$ALLOWED_USERS_FILE" << USERFILE
{
  "admin": ${ADMIN_ID},
  "allowed_users": [${ADMIN_ID}],
  "authorized": [${ADMIN_ID}],
  "pending": []
}
USERFILE
else
    echo "✓ ${ALLOWED_USERS_FILE} already exists"
fi

# Initialize user-locations.json if it doesn't exist
USER_LOCATIONS_FILE="${DATA_DIR}/user-locations.json"
if [ ! -f "$USER_LOCATIONS_FILE" ]; then
    echo "Creating ${USER_LOCATIONS_FILE}..."
    echo '{}' > "$USER_LOCATIONS_FILE"
else
    echo "✓ ${USER_LOCATIONS_FILE} already exists"
fi

# Initialize user-preferences.json if it doesn't exist
USER_PREFERENCES_FILE="${DATA_DIR}/user-preferences.json"
if [ ! -f "$USER_PREFERENCES_FILE" ]; then
    echo "Creating ${USER_PREFERENCES_FILE}..."
    echo '{}' > "$USER_PREFERENCES_FILE"
else
    echo "✓ ${USER_PREFERENCES_FILE} already exists"
fi

# Initialize pending-input.json if it doesn't exist
PENDING_INPUT_FILE="${DATA_DIR}/pending-input.json"
if [ ! -f "$PENDING_INPUT_FILE" ]; then
    echo "Creating ${PENDING_INPUT_FILE}..."
    echo '{}' > "$PENDING_INPUT_FILE"
else
    echo "✓ ${PENDING_INPUT_FILE} already exists"
fi

echo "✓ Weather bot data initialization complete"
