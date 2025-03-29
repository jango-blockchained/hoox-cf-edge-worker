#!/bin/bash

# scripts/keys.sh - Central key management functions
# This script provides functions to get, generate, and store API keys

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Location of the keys storage file (hidden in the project root)
KEYS_DIR="$(dirname "$0")/../.keys"
LOCAL_KEYS_FILE="$KEYS_DIR/local_keys.env"
PROD_KEYS_FILE="$KEYS_DIR/prod_keys.env"

# Ensure the keys directory exists
mkdir -p "$KEYS_DIR"
touch "$LOCAL_KEYS_FILE"
touch "$PROD_KEYS_FILE"
chmod 600 "$LOCAL_KEYS_FILE" "$PROD_KEYS_FILE"

# Function to generate a secure key
generate_key() {
    local length=$1
    openssl rand -base64 $((length * 3/4)) | tr -dc 'a-zA-Z0-9' | head -c $length
}

# Function to get a key from storage, or generate a new one if it doesn't exist
get_or_generate_key() {
    local key_name=$1
    local environment=$2  # "local" or "prod"
    local length=${3:-64}
    local storage_file
    
    if [[ "$environment" == "local" ]]; then
        storage_file="$LOCAL_KEYS_FILE"
    else
        storage_file="$PROD_KEYS_FILE"
    fi
    
    # Check if the key exists in the file
    if grep -q "^$key_name=" "$storage_file"; then
        # Extract the key value
        key_value=$(grep "^$key_name=" "$storage_file" | cut -d'=' -f2)
        echo -e "${BLUE}Using existing $key_name...${NC}"
    else
        # Generate a new key
        key_value=$(generate_key $length)
        echo -e "${YELLOW}Generated new $key_name...${NC}"
        # Store the key
        echo "$key_name=$key_value" >> "$storage_file"
    fi
    
    echo "$key_value"
}

# Function to update a key and store it
update_key() {
    local key_name=$1
    local environment=$2  # "local" or "prod"
    local length=${3:-64}
    local storage_file
    
    if [[ "$environment" == "local" ]]; then
        storage_file="$LOCAL_KEYS_FILE"
    else
        storage_file="$PROD_KEYS_FILE"
    fi
    
    # Generate a new key
    key_value=$(generate_key $length)
    
    # Update or add the key in the file
    if grep -q "^$key_name=" "$storage_file"; then
        # Update existing key
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS uses BSD sed
            sed -i '' "s/^$key_name=.*/$key_name=$key_value/" "$storage_file"
        else
            # Linux uses GNU sed
            sed -i "s/^$key_name=.*/$key_name=$key_value/" "$storage_file"
        fi
    else
        # Add new key
        echo "$key_name=$key_value" >> "$storage_file"
    fi
    
    echo "$key_value"
}

# Function to display available keys
list_keys() {
    local environment=$1  # "local" or "prod"
    local storage_file
    
    if [[ "$environment" == "local" ]]; then
        storage_file="$LOCAL_KEYS_FILE"
        echo -e "${BLUE}Local Development Keys:${NC}"
    else
        storage_file="$PROD_KEYS_FILE"
        echo -e "${BLUE}Production Keys:${NC}"
    fi
    
    if [ -s "$storage_file" ]; then
        while IFS='=' read -r key value; do
            echo -e "${YELLOW}$key${NC}: ${GREEN}$value${NC}"
        done < "$storage_file"
    else
        echo -e "${YELLOW}No keys stored yet.${NC}"
    fi
}

# Direct usage of the script
if [ "$1" == "list" ]; then
    if [ "$2" == "local" ]; then
        list_keys "local"
    elif [ "$2" == "prod" ]; then
        list_keys "prod"
    else
        list_keys "local"
        echo
        list_keys "prod"
    fi
elif [ "$1" == "generate" ]; then
    key_type=${2:-"API_SECRET_KEY"}
    environment=${3:-"local"}
    length=${4:-64}
    
    key=$(update_key "$key_type" "$environment" "$length")
    echo -e "${YELLOW}Generated $key_type (${environment}):${NC} ${GREEN}$key${NC}"
elif [ "$1" == "get" ]; then
    key_type=${2:-"API_SECRET_KEY"}
    environment=${3:-"local"}
    length=${4:-64}
    
    key=$(get_or_generate_key "$key_type" "$environment" "$length")
    echo -e "${YELLOW}$key_type (${environment}):${NC} ${GREEN}$key${NC}"
fi 