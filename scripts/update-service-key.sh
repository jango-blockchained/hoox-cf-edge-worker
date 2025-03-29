#!/bin/bash

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=============================================${NC}"
echo -e "${YELLOW}  Update INTERNAL_SERVICE_KEY for Production ${NC}"
echo -e "${YELLOW}=============================================${NC}"
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

# Check if wrangler is available
if ! command -v bunx &> /dev/null; then
    echo -e "${RED}Error: Bun is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if keys script exists
if [ ! -f "$KEYS_SCRIPT" ]; then
    echo -e "${RED}Error: Keys management script not found at: $KEYS_SCRIPT${NC}"
    exit 1
fi

# Navigate to the root directory
cd "${PROJECT_ROOT}" || {
    echo -e "${RED}Error: Could not navigate to the root directory.${NC}"
    exit 1
}

# Check for existing service key
echo -e "${BLUE}Checking for existing INTERNAL_SERVICE_KEY...${NC}"
CURRENT_SERVICE_KEY=$("$KEYS_SCRIPT" get "INTERNAL_SERVICE_KEY" "prod" 64)

if [ -z "$CURRENT_SERVICE_KEY" ]; then
    echo -e "${RED}Error: Failed to get or generate service key.${NC}"
    exit 1
fi

echo -e "INTERNAL_SERVICE_KEY: ${GREEN}$CURRENT_SERVICE_KEY${NC}"
echo

# Ask if user wants to use the existing key or generate a new one
echo -e "${YELLOW}Options:${NC}"
echo -e "  ${BLUE}[1]${NC} - Use the existing key"
echo -e "  ${BLUE}[2]${NC} - Generate a new key"
read -p "Select an option (1/2): " key_option

if [[ "$key_option" == "2" ]]; then
    echo -e "\n${YELLOW}Generating a new INTERNAL_SERVICE_KEY...${NC}"
    NEW_SERVICE_KEY=$("$KEYS_SCRIPT" generate "INTERNAL_SERVICE_KEY" "prod" 64)
    
    if [ -z "$NEW_SERVICE_KEY" ]; then
        echo -e "${RED}Error: Failed to generate a new service key.${NC}"
        exit 1
    fi
    
    echo -e "New INTERNAL_SERVICE_KEY: ${GREEN}$NEW_SERVICE_KEY${NC}"
    SERVICE_KEY_TO_USE="$NEW_SERVICE_KEY"
else
    echo -e "\n${BLUE}Using existing INTERNAL_SERVICE_KEY.${NC}"
    SERVICE_KEY_TO_USE="$CURRENT_SERVICE_KEY"
fi

echo

# Confirm before updating
read -p "Do you want to update the INTERNAL_SERVICE_KEY for all workers in production? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

# Get list of all worker directories
worker_dirs=$(find workers -maxdepth 1 -type d -not -path "workers" | sort)

# Update the key for each worker
for worker_path in $worker_dirs; do
    # Extract just the worker name from the path
    worker_name=$(basename "$worker_path")
    
    echo -e "\nUpdating INTERNAL_SERVICE_KEY for ${YELLOW}$worker_name${NC}..."
    cd "${PROJECT_ROOT}/${worker_path}" || {
        echo -e "${RED}Error: Could not navigate to $worker_path.${NC}"
        continue
    }
    
    # Check if wrangler.toml exists
    if [ ! -f wrangler.toml ]; then
        echo -e "${RED}Error: wrangler.toml not found in $worker_path${NC}"
        cd - > /dev/null
        continue
    }
    
    # Update the secret
    echo "$SERVICE_KEY_TO_USE" | bunx wrangler secret put INTERNAL_SERVICE_KEY
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully updated INTERNAL_SERVICE_KEY for $worker_name${NC}"
    else
        echo -e "${RED}❌ Failed to update INTERNAL_SERVICE_KEY for $worker_name${NC}"
    fi
    
    cd - > /dev/null
done

echo -e "\n${GREEN}✅ Key update process completed!${NC}"
echo -e "${YELLOW}IMPORTANT: Keep this key secure!${NC}" 