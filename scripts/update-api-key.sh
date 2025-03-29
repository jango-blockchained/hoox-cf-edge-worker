#!/bin/bash

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}  Update API_SECRET_KEY for Production ${NC}"
echo -e "${YELLOW}=======================================${NC}"
echo

# Check if OpenSSL is installed
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error: OpenSSL is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if wrangler is available
if ! command -v bunx &> /dev/null; then
    echo -e "${RED}Error: Bun is not installed. Please install it first.${NC}"
    exit 1
fi

# Navigate to webhook-receiver directory
cd "$(dirname "$0")/../workers/webhook-receiver" || {
    echo -e "${RED}Error: Could not navigate to webhook-receiver directory.${NC}"
    exit 1
}

# Check for existing key first
echo -e "${BLUE}Checking for existing API_SECRET_KEY...${NC}"
CURRENT_KEY=$("$(dirname "$0")/keys.sh" get "API_SECRET_KEY" "prod" 64)

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
    NEW_API_KEY=$("$(dirname "$0")/keys.sh" generate "API_SECRET_KEY" "prod" 64)
    
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
read -p "Do you want to update the API_SECRET_KEY in production? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

echo "Updating API_SECRET_KEY in production..."
echo "$API_KEY_TO_USE" | bunx wrangler secret put API_SECRET_KEY

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully updated API_SECRET_KEY for webhook-receiver in production!${NC}"
    echo -e "${YELLOW}IMPORTANT: Keep this key secure and update your clients accordingly.${NC}"
else
    echo -e "${RED}❌ Failed to update API_SECRET_KEY.${NC}"
fi

cd - > /dev/null 