#!/bin/bash

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script's directory using absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
KEYS_SCRIPT="${SCRIPT_DIR}/keys.sh"

# Function to check for and configure Cloudflare API token
check_cloudflare_token() {
    echo -e "${BLUE}Checking for Cloudflare API token...${NC}"
    
    # Check if CLOUDFLARE_API_TOKEN is already set
    if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
        echo -e "${GREEN}CLOUDFLARE_API_TOKEN is already set in the environment.${NC}"
        
        # Verify token is working
        echo -e "Verifying token..."
        if bunx wrangler whoami > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Token is valid!${NC}"
            return 0
        else
            echo -e "${RED}❌ Token validation failed. Let's configure a new one.${NC}"
        fi
    else
        echo -e "${YELLOW}CLOUDFLARE_API_TOKEN not found in environment variables.${NC}"
    fi
    
    echo -e "\n${BLUE}Cloudflare API Token Configuration:${NC}"
    echo -e "${YELLOW}A Cloudflare API token with 'Edit Workers' permission is required.${NC}"
    
    echo -e "\n${BLUE}Options:${NC}"
    echo -e "  ${YELLOW}[1]${NC} - I already have a token (enter it now)"
    echo -e "  ${YELLOW}[2]${NC} - Help me create a new token"
    echo -e "  ${YELLOW}[3]${NC} - Skip for now (script may fail later)"
    read -p "Select option (1-3): " token_option
    
    case $token_option in
        1)
            read -p "Enter your Cloudflare API token: " api_token
            if [ -n "$api_token" ]; then
                export CLOUDFLARE_API_TOKEN="$api_token"
                echo -e "${GREEN}Token set for this session.${NC}"
                
                # Ask if they want to save it to their profile
                read -p "Would you like to save this token to your shell profile? (y/n): " save_token
                if [[ "$save_token" == "y" || "$save_token" == "Y" ]]; then
                    # Determine which shell profile to use
                    if [ -f "$HOME/.zshrc" ]; then
                        PROFILE_FILE="$HOME/.zshrc"
                    elif [ -f "$HOME/.bashrc" ]; then
                        PROFILE_FILE="$HOME/.bashrc"
                    elif [ -f "$HOME/.bash_profile" ]; then
                        PROFILE_FILE="$HOME/.bash_profile"
                    else
                        echo -e "${YELLOW}Could not determine your shell profile. The token will only be available for this session.${NC}"
                        return 0
                    fi
                    
                    # Add the token to the profile
                    echo -e "\n# Cloudflare API Token for Wrangler" >> "$PROFILE_FILE"
                    echo "export CLOUDFLARE_API_TOKEN='$api_token'" >> "$PROFILE_FILE"
                    echo -e "${GREEN}Token added to $PROFILE_FILE${NC}"
                    echo -e "${YELLOW}Please run 'source $PROFILE_FILE' or start a new terminal session after this script completes.${NC}"
                fi
            else
                echo -e "${RED}No token provided. Continuing without a token (may cause errors).${NC}"
            fi
            ;;
        2)
            echo -e "\n${BLUE}How to create a Cloudflare API token:${NC}"
            echo -e "1. Go to: ${YELLOW}https://dash.cloudflare.com/profile/api-tokens${NC}"
            echo -e "2. Click 'Create Token'"
            echo -e "3. Choose 'Create Custom Token'"
            echo -e "4. Set token name (e.g., 'Workers Management')"
            echo -e "5. Add permissions:"
            echo -e "   - Account > Worker Scripts > Edit"
            echo -e "   - Account > Workers KV Storage > Edit"
            echo -e "   - Account > Workers D1 > Edit (if using D1)"
            echo -e "6. Set Zone Resources (typically 'All zones')"
            echo -e "7. Click 'Continue to Summary' then 'Create Token'"
            echo -e "8. Copy the displayed token\n"
            
            read -p "Have you created the token? Enter it now (or leave empty to skip): " api_token
            if [ -n "$api_token" ]; then
                export CLOUDFLARE_API_TOKEN="$api_token"
                echo -e "${GREEN}Token set for this session.${NC}"
                
                # Ask if they want to save it to their profile
                read -p "Would you like to save this token to your shell profile? (y/n): " save_token
                if [[ "$save_token" == "y" || "$save_token" == "Y" ]]; then
                    # Determine which shell profile to use
                    if [ -f "$HOME/.zshrc" ]; then
                        PROFILE_FILE="$HOME/.zshrc"
                    elif [ -f "$HOME/.bashrc" ]; then
                        PROFILE_FILE="$HOME/.bashrc"
                    elif [ -f "$HOME/.bash_profile" ]; then
                        PROFILE_FILE="$HOME/.bash_profile"
                    else
                        echo -e "${YELLOW}Could not determine your shell profile. The token will only be available for this session.${NC}"
                        return 0
                    fi
                    
                    # Add the token to the profile
                    echo -e "\n# Cloudflare API Token for Wrangler" >> "$PROFILE_FILE"
                    echo "export CLOUDFLARE_API_TOKEN='$api_token'" >> "$PROFILE_FILE"
                    echo -e "${GREEN}Token added to $PROFILE_FILE${NC}"
                    echo -e "${YELLOW}Please run 'source $PROFILE_FILE' or start a new terminal session after this script completes.${NC}"
                fi
            else
                echo -e "${RED}No token provided. Continuing without a token (may cause errors).${NC}"
            fi
            ;;
        3)
            echo -e "${YELLOW}Skipping Cloudflare API token configuration.${NC}"
            echo -e "${RED}Warning: Operations requiring Cloudflare API access may fail.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option. Continuing without a token (may cause errors).${NC}"
            ;;
    esac
    echo
}

# Function to set secrets for a worker
set_worker_secrets() {
    local worker_name=$1
    local environment=$2  # "local" or "prod"
    shift 2
    local secrets=("$@")
    
    echo -e "${BLUE}Setting secrets for $worker_name...${NC}"
    cd "${PROJECT_ROOT}/workers/$worker_name" || exit 1
    
    for secret in "${secrets[@]}"; do
        echo -e "${YELLOW}Setting $secret...${NC}"
        
        # If the secret is related to API keys, offer a generated value
        if [[ "$secret" == "API_SECRET_KEY" || "$secret" == "INTERNAL_SERVICE_KEY" ]]; then
            # Get or generate the key using keys.sh
            default_value=$("$KEYS_SCRIPT" get "$secret" "$environment" 64)
            echo -e "Generated/Stored: ${GREEN}$default_value${NC}"
            
            # Let user choose to use the existing key, generate a new one, or enter a custom value
            echo -e "${YELLOW}Options:${NC}"
            echo -e "  ${BLUE}[1]${NC} - Use the existing/generated key"
            echo -e "  ${BLUE}[2]${NC} - Generate a new key"
            echo -e "  ${BLUE}[3]${NC} - Enter a custom value"
            read -p "Select an option (1/2/3): " key_option
            
            if [[ "$key_option" == "2" ]]; then
                # Generate a new key
                default_value=$("$KEYS_SCRIPT" generate "$secret" "$environment" 64)
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
                        STORAGE_FILE="${PROJECT_ROOT}/.keys/local_keys.env"
                    else
                        STORAGE_FILE="${PROJECT_ROOT}/.keys/prod_keys.env"
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
    
    cd "${PROJECT_ROOT}"
    echo -e "${GREEN}✅ Completed setting secrets for $worker_name${NC}"
    echo
}

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
    
    # Check for Cloudflare API token when setting production secrets
    check_cloudflare_token
else
    environment="local"
    echo -e "\n${YELLOW}Setting up LOCAL DEVELOPMENT secrets...${NC}"
fi

# Navigate to the root directory
cd "${PROJECT_ROOT}" || {
    echo -e "${RED}Error: Could not navigate to the root directory.${NC}"
    exit 1
}

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