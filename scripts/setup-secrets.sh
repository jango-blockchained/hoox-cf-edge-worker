#!/bin/bash

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to set secrets for a worker
set_worker_secrets() {
    local worker_name=$1
    local environment=$2  # "local" or "prod"
    shift 2
    local secrets=("$@")
    
    echo -e "${BLUE}Setting secrets for $worker_name...${NC}"
    cd "workers/$worker_name" || exit 1
    
    for secret in "${secrets[@]}"; do
        echo -e "${YELLOW}Setting $secret...${NC}"
        
        # If the secret is related to API keys, offer a generated value
        if [[ "$secret" == "API_SECRET_KEY" || "$secret" == "INTERNAL_SERVICE_KEY" ]]; then
            # Get or generate the key using keys.sh
            default_value=$("$(dirname "$0")/keys.sh" get "$secret" "$environment" 64)
            echo -e "Generated/Stored: ${GREEN}$default_value${NC}"
            
            # Let user choose to use the existing key, generate a new one, or enter a custom value
            echo -e "${YELLOW}Options:${NC}"
            echo -e "  ${BLUE}[1]${NC} - Use the existing/generated key"
            echo -e "  ${BLUE}[2]${NC} - Generate a new key"
            echo -e "  ${BLUE}[3]${NC} - Enter a custom value"
            read -p "Select an option (1/2/3): " key_option
            
            if [[ "$key_option" == "2" ]]; then
                # Generate a new key
                default_value=$("$(dirname "$0")/keys.sh" generate "$secret" "$environment" 64)
                echo -e "New key: ${GREEN}$default_value${NC}"
                secret_value="$default_value"
            elif [[ "$key_option" == "3" ]]; then
                # Custom value
                read -p "Enter value for $secret: " secret_value
                if [ -z "$secret_value" ]; then
                    echo -e "${RED}No value provided, using the existing/generated key.${NC}"
                    secret_value="$default_value"
                else
                    # Store the custom value in our key storage
                    echo -e "Storing custom value in key storage..."
                    if [[ "$environment" == "local" ]]; then
                        STORAGE_FILE="$(dirname "$0")/../.keys/local_keys.env"
                    else
                        STORAGE_FILE="$(dirname "$0")/../.keys/prod_keys.env"
                    fi
                    
                    if grep -q "^$secret=" "$STORAGE_FILE"; then
                        if [[ "$OSTYPE" == "darwin"* ]]; then
                            sed -i '' "s/^$secret=.*/$secret=$secret_value/" "$STORAGE_FILE"
                        else
                            sed -i "s/^$secret=.*/$secret=$secret_value/" "$STORAGE_FILE"
                        fi
                    else
                        echo "$secret=$secret_value" >> "$STORAGE_FILE"
                    fi
                fi
            else
                # Use existing key
                secret_value="$default_value"
            fi
        else
            # For non-key secrets
            read -p "Enter value for $secret: " secret_value
        fi
        
        # Deploy the secret
        if [[ "$environment" == "local" ]]; then
            # For local, add to .dev.vars
            if [ ! -f ".dev.vars" ]; then
                touch ".dev.vars"
            fi
            
            if grep -q "^$secret=" ".dev.vars"; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "s/^$secret=.*/$secret=$secret_value/" ".dev.vars"
                else
                    sed -i "s/^$secret=.*/$secret=$secret_value/" ".dev.vars"
                fi
            else
                echo "$secret=$secret_value" >> ".dev.vars"
            fi
            echo -e "${GREEN}✅ Added to .dev.vars${NC}"
        else
            # For production, use wrangler secret
            echo "$secret_value" | bunx wrangler secret put "$secret"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Secret set with wrangler${NC}"
            else
                echo -e "${RED}❌ Failed to set secret with wrangler${NC}"
            fi
        fi
    done
    
    cd ../..
    echo -e "${GREEN}✅ Completed setting secrets for $worker_name${NC}"
    echo
}

# Check if OpenSSL is installed
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error: OpenSSL is not installed. Please install it first.${NC}"
    exit 1
fi

# Main script
echo -e "${YELLOW}🔐 Starting secrets setup for all workers...${NC}"

# Ask for environment
echo -e "${YELLOW}Choose environment:${NC}"
echo -e "  ${BLUE}[1]${NC} - Local Development"
echo -e "  ${BLUE}[2]${NC} - Production"
read -p "Select environment (1/2): " env_option

if [[ "$env_option" == "2" ]]; then
    environment="prod"
    echo -e "\n${YELLOW}Setting up PRODUCTION secrets...${NC}"
    
    # Check if wrangler is available
    if ! command -v bunx &> /dev/null; then
        echo -e "${RED}Error: Bun is not installed. Please install it first.${NC}"
        exit 1
    fi
else
    environment="local"
    echo -e "\n${YELLOW}Setting up LOCAL DEVELOPMENT secrets...${NC}"
fi

# Webhook Receiver secrets
webhook_secrets=("API_SECRET_KEY" "INTERNAL_SERVICE_KEY")
set_worker_secrets "webhook-receiver" "$environment" "${webhook_secrets[@]}"

# Telegram Worker secrets
telegram_secrets=("INTERNAL_SERVICE_KEY" "TELEGRAM_BOT_TOKEN" "TELEGRAM_CHAT_ID")
set_worker_secrets "telegram-worker" "$environment" "${telegram_secrets[@]}"

# Trade Worker secrets
trade_secrets=("INTERNAL_SERVICE_KEY" "MEXC_API_KEY" "MEXC_API_SECRET" "D1_DATABASE_URL")
set_worker_secrets "trade-worker" "$environment" "${trade_secrets[@]}"

# D1 Worker secrets
d1_secrets=("INTERNAL_SERVICE_KEY")
set_worker_secrets "d1-worker" "$environment" "${d1_secrets[@]}"

echo -e "${GREEN}✨ All secrets have been configured!${NC}" 