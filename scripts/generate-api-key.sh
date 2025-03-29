#!/bin/bash

# scripts/generate-api-key.sh - Script to generate secure API keys
# Shell version of the original JavaScript script

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to generate a secure key
generate_key() {
    local length=$1
    # Use OpenSSL to generate a secure random string
    openssl rand -base64 $((length * 3/4)) | tr -dc 'a-zA-Z0-9' | head -c $length
}

# Default lengths
API_KEY_LENGTH=48
SERVICE_KEY_LENGTH=64

# Check if custom lengths were provided
if [ ! -z "$1" ]; then
    API_KEY_LENGTH=$1
fi

if [ ! -z "$2" ]; then
    SERVICE_KEY_LENGTH=$2
fi

# Generate keys
API_KEY=$(generate_key $API_KEY_LENGTH)
SERVICE_KEY=$(generate_key $SERVICE_KEY_LENGTH)

# Output the keys
echo -e "${YELLOW}Generated API Key:${NC} ${GREEN}$API_KEY${NC}"
echo -e "${YELLOW}Generated Internal Service Key:${NC} ${GREEN}$SERVICE_KEY${NC}"

# If an output file is specified, save the keys there
if [ ! -z "$3" ]; then
    echo "API_KEY=$API_KEY" > "$3"
    echo "INTERNAL_SERVICE_KEY=$SERVICE_KEY" >> "$3"
    echo -e "Keys saved to ${YELLOW}$3${NC}"
fi 