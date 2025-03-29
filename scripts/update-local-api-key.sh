#!/bin/bash

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}  Update API_SECRET_KEY for Local Dev  ${NC}"
echo -e "${YELLOW}=======================================${NC}"
echo

# Get the script's directory using absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
KEYS_SCRIPT="${SCRIPT_DIR}/keys.sh"

# Check if OpenSSL is installed
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error: OpenSSL is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if keys script exists
if [ ! -f "$KEYS_SCRIPT" ]; then
    echo -e "${RED}Error: Keys management script not found at: $KEYS_SCRIPT${NC}"
    exit 1
fi

# Navigate to webhook-receiver directory
cd "${PROJECT_ROOT}/workers/webhook-receiver" || {
    echo -e "${RED}Error: Could not navigate to webhook-receiver directory.${NC}"
    exit 1
}

# Check for existing key first
echo -e "${BLUE}Checking for existing API_SECRET_KEY...${NC}"
CURRENT_KEY=$("$KEYS_SCRIPT" get "API_SECRET_KEY" "local" 64)

if [ -z "$CURRENT_KEY" ]; then
    echo -e "${RED}Error: Failed to get or generate API key.${NC}"
    exit 1
fi

echo -e "API_SECRET_KEY: ${GREEN}$CURRENT_KEY${NC}"
echo

# Ask if user wants to use the existing key or generate a new one
echo -e "${YELLOW}Options:${NC}"
echo -e "  ${BLUE}[1]${NC} - Use the existing key"
echo -e "  ${BLUE}[2]${NC} - Generate a new key"
read -p "Select an option (1/2): " key_option

if [[ "$key_option" == "2" ]]; then
    echo -e "\n${YELLOW}Generating a new API_SECRET_KEY...${NC}"
    NEW_API_KEY=$("$KEYS_SCRIPT" generate "API_SECRET_KEY" "local" 64)
    
    if [ -z "$NEW_API_KEY" ]; then
        echo -e "${RED}Error: Failed to generate a new API key.${NC}"
        exit 1
    fi
    
    echo -e "New API_SECRET_KEY: ${GREEN}$NEW_API_KEY${NC}"
    API_KEY_TO_USE="$NEW_API_KEY"
else
    echo -e "\n${BLUE}Using existing API_SECRET_KEY.${NC}"
    API_KEY_TO_USE="$CURRENT_KEY"
fi

echo

# Confirm before updating
read -p "Do you want to update the API_SECRET_KEY for local development? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

# Create or update .dev.vars file
DEV_VARS_FILE=".dev.vars"

# Check if .dev.vars exists
if [ -f "$DEV_VARS_FILE" ]; then
    # Check if API_SECRET_KEY already exists in the file
    if grep -q "^API_SECRET_KEY=" "$DEV_VARS_FILE"; then
        # Update existing entry
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS uses BSD sed
            sed -i '' "s/^API_SECRET_KEY=.*/API_SECRET_KEY=$API_KEY_TO_USE/" "$DEV_VARS_FILE"
        else
            # Linux uses GNU sed
            sed -i "s/^API_SECRET_KEY=.*/API_SECRET_KEY=$API_KEY_TO_USE/" "$DEV_VARS_FILE"
        fi
    else
        # Add new entry
        echo "API_SECRET_KEY=$API_KEY_TO_USE" >> "$DEV_VARS_FILE"
    fi
else
    # Create new file
    echo "API_SECRET_KEY=$API_KEY_TO_USE" > "$DEV_VARS_FILE"
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully updated API_SECRET_KEY in .dev.vars for webhook-receiver!${NC}"
    echo -e "${YELLOW}IMPORTANT: This key is only for local development.${NC}"
else
    echo -e "${RED}❌ Failed to update API_SECRET_KEY in .dev.vars.${NC}"
fi

cd - > /dev/null 