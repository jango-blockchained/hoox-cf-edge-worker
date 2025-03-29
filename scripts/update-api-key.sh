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
    echo -e "${RED}Error: Keys management script not found at: $KEYS_SCRIPT${NC}" >&2
    exit 1
fi

# Function to check for Cloudflare API token
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
    echo -e "${YELLOW}A Cloudflare API token with 'Edit Workers' permission is required to deploy keys to Cloudflare.${NC}"
    
    echo -e "\n${BLUE}Options:${NC}"
    echo -e "  ${YELLOW}[1]${NC} - I already have a token (enter it now)"
    echo -e "  ${YELLOW}[2]${NC} - Help me create a new token"
    echo -e "  ${YELLOW}[3]${NC} - Skip for now (local-only key update)"
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
                return 0
            else
                echo -e "${RED}No token provided. Continuing with local-only key update.${NC}"
                return 1
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
                return 0
            else
                echo -e "${RED}No token provided. Continuing with local-only key update.${NC}"
                return 1
            fi
            ;;
        3)
            echo -e "${YELLOW}Skipping Cloudflare API token configuration.${NC}"
            echo -e "${YELLOW}The API key will only be updated locally, not in Cloudflare.${NC}"
            return 1
            ;;
        *)
            echo -e "${RED}Invalid option. Continuing with local-only key update.${NC}"
            return 1
            ;;
    esac
}

# Check for existing API_SECRET_KEY
echo -e "${BLUE}Checking for existing API_SECRET_KEY...${NC}"
existing_key=$("$KEYS_SCRIPT" get API_SECRET_KEY prod)

if [ -n "$existing_key" ]; then
  echo -e "${GREEN}API_SECRET_KEY (prod): $existing_key${NC}"
else
  echo -e "${YELLOW}No existing production API_SECRET_KEY found. Generating a new one...${NC}"
  existing_key=$("$KEYS_SCRIPT" generate API_SECRET_KEY prod 64)
  echo -e "${GREEN}API_SECRET_KEY (prod): $existing_key${NC}"
fi

# Let user choose to use the existing key or generate a new one
echo -e "\n${YELLOW}Options:${NC}"
echo -e "  ${BLUE}[1]${NC} - Use the existing key"
echo -e "  ${BLUE}[2]${NC} - Generate a new key"
read -p "Select an option (1/2): " key_option

if [[ "$key_option" == "2" ]]; then
  # Generate a new key
  api_key=$("$KEYS_SCRIPT" generate API_SECRET_KEY prod 64)
  echo -e "${GREEN}New API_SECRET_KEY: $api_key${NC}"
else
  # Use the existing key
  api_key="$existing_key"
  echo -e "${GREEN}Using existing API_SECRET_KEY.${NC}"
fi

# Ask user if they want to update the API key in production
echo
read -p "Do you want to update the API_SECRET_KEY in production? (y/n): " update_prod

if [[ "$update_prod" == "y" || "$update_prod" == "Y" ]]; then
  # Check for and configure Cloudflare API token
  if ! check_cloudflare_token; then
    echo -e "${YELLOW}API key has been generated and stored locally.${NC}"
    echo -e "${YELLOW}To deploy to Cloudflare later, set up a Cloudflare API token and run this script again.${NC}"
    exit 0
  fi
  
  # Update the API key in production using wrangler
  echo -e "\n${BLUE}Updating API_SECRET_KEY in production...${NC}"
  
  # Navigate to the webhook-receiver worker directory
  cd "${PROJECT_ROOT}/workers/webhook-receiver" || {
    echo -e "${RED}Error: Could not navigate to webhook-receiver directory.${NC}" >&2
    echo -e "${YELLOW}API key has been generated and stored locally but not deployed.${NC}"
    exit 1
  }
  
  # Update the secret in production
  echo "$api_key" | bunx wrangler secret put API_SECRET_KEY
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ API secret key updated successfully in production!${NC}"
    cd "${PROJECT_ROOT}"
  else
    echo -e "${RED}❌ Failed to update API secret key in production.${NC}" >&2
    echo -e "${YELLOW}API key has been generated and stored locally but not deployed.${NC}"
    echo -e "${YELLOW}Check the error message above or try again later.${NC}"
    cd "${PROJECT_ROOT}"
    exit 1
  fi
else
  echo -e "${YELLOW}API key has been generated and stored locally.${NC}"
  echo -e "${YELLOW}No changes were made to the production environment.${NC}"
fi

echo -e "\n${GREEN}✅ Operation completed.${NC}" 