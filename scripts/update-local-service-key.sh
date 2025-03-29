#!/bin/bash

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=============================================${NC}"
echo -e "${YELLOW}  Update INTERNAL_SERVICE_KEY for Local Dev  ${NC}"
echo -e "${YELLOW}=============================================${NC}"
echo

# Check if OpenSSL is installed
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error: OpenSSL is not installed. Please install it first.${NC}"
    exit 1
fi

# Navigate to the root directory
cd "$(dirname "$0")/.." || {
    echo -e "${RED}Error: Could not navigate to the root directory.${NC}"
    exit 1
}

# Check for existing service key
echo -e "${BLUE}Checking for existing INTERNAL_SERVICE_KEY...${NC}"
CURRENT_SERVICE_KEY=$("$(dirname "$0")/keys.sh" get "INTERNAL_SERVICE_KEY" "local" 64)

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
    NEW_SERVICE_KEY=$("$(dirname "$0")/keys.sh" generate "INTERNAL_SERVICE_KEY" "local" 64)
    
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
read -p "Do you want to update the INTERNAL_SERVICE_KEY for all workers for local development? (y/n): " confirm
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
    cd "$worker_path" || {
        echo -e "${RED}Error: Could not navigate to $worker_path.${NC}"
        continue
    }
    
    DEV_VARS_FILE=".dev.vars"
    
    # Check if .dev.vars exists
    if [ -f "$DEV_VARS_FILE" ]; then
        # Check if INTERNAL_SERVICE_KEY already exists in the file
        if grep -q "^INTERNAL_SERVICE_KEY=" "$DEV_VARS_FILE"; then
            # Update existing entry
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS uses BSD sed
                sed -i '' "s/^INTERNAL_SERVICE_KEY=.*/INTERNAL_SERVICE_KEY=$SERVICE_KEY_TO_USE/" "$DEV_VARS_FILE"
            else
                # Linux uses GNU sed
                sed -i "s/^INTERNAL_SERVICE_KEY=.*/INTERNAL_SERVICE_KEY=$SERVICE_KEY_TO_USE/" "$DEV_VARS_FILE"
            fi
        else
            # Add new entry
            echo "INTERNAL_SERVICE_KEY=$SERVICE_KEY_TO_USE" >> "$DEV_VARS_FILE"
        fi
    else
        # Create new file
        echo "INTERNAL_SERVICE_KEY=$SERVICE_KEY_TO_USE" > "$DEV_VARS_FILE"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully updated INTERNAL_SERVICE_KEY in .dev.vars for $worker_name${NC}"
    else
        echo -e "${RED}❌ Failed to update INTERNAL_SERVICE_KEY in .dev.vars for $worker_name${NC}"
    fi
    
    cd - > /dev/null
done

echo -e "\n${GREEN}✅ Local development key update process completed!${NC}"
echo -e "${YELLOW}IMPORTANT: This key is only for local development!${NC}" 