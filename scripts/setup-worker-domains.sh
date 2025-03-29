#!/bin/bash

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=============================================${NC}"
echo -e "${YELLOW}  Setup Custom Domains for Cloudflare Workers ${NC}"
echo -e "${YELLOW}=============================================${NC}"
echo

# Check if wrangler is available
if ! command -v bunx &> /dev/null; then
    echo -e "${RED}Error: Bun is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if jq is installed (needed for JSON processing)
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Please install it first.${NC}"
    echo "For Ubuntu/Debian: sudo apt-get install jq"
    echo "For macOS with Homebrew: brew install jq"
    exit 1
fi

# Navigate to the root directory
cd "$(dirname "$0")/.." || {
    echo -e "${RED}Error: Could not navigate to the root directory.${NC}"
    exit 1
}

# Get list of all worker directories
worker_dirs=$(find workers -maxdepth 1 -type d -not -path "workers" | sort)

# Define the base custom domain pattern
read -p "Enter your Cloudflare account subdomain (e.g., 'cryptolinx'): " account_subdomain

if [ -z "$account_subdomain" ]; then
    echo -e "${RED}Error: Account subdomain is required.${NC}"
    exit 1
fi

domains=()
worker_names=()

# First pass: Get all worker information and domains
echo -e "\n${BLUE}Checking worker configurations...${NC}"
for worker_path in $worker_dirs; do
    # Extract just the worker name from the path
    worker_name=$(basename "$worker_path")
    worker_names+=("$worker_name")
    
    # Check if wrangler.toml exists
    if [ ! -f "$worker_path/wrangler.toml" ]; then
        echo -e "${RED}Error: wrangler.toml not found in $worker_path${NC}"
        exit 1
    fi
    
    # Define the custom domain based on the worker name
    domain="${worker_name}.${account_subdomain}.workers.dev"
    domains+=("$domain")
    
    echo -e "Worker: ${YELLOW}$worker_name${NC} -> Domain: ${BLUE}$domain${NC}"
done

echo
# Confirm before proceeding
read -p "Are these domains correct? This will update the worker configurations. (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

# Second pass: Update the worker configurations
echo -e "\n${BLUE}Updating worker configurations and deploying...${NC}"

# Map to store worker URLs for cross-references
declare -A worker_urls

# Populate the map with URLs
for i in "${!worker_names[@]}"; do
    worker_name="${worker_names[$i]}"
    domain="${domains[$i]}"
    worker_urls["$worker_name"]="https://$domain"
done

# Now update configurations and deploy
for i in "${!worker_names[@]}"; do
    worker_name="${worker_names[$i]}"
    worker_path="workers/$worker_name"
    domain="${domains[$i]}"
    
    echo -e "\n${BLUE}Configuring worker: ${YELLOW}$worker_name${NC}"
    
    # Read the wrangler.toml file
    toml_file="$worker_path/wrangler.toml"
    
    # Check for dependencies on other workers and update URLs
    needs_update=false
    
    # Check for references to other workers in vars section
    if grep -q "\[vars\]" "$toml_file"; then
        for other_worker in "${worker_names[@]}"; do
            # Skip self-references
            if [ "$other_worker" == "$worker_name" ]; then
                continue
            fi
            
            # Check if this worker references the other worker in uppercase format (e.g., TRADE_WORKER_URL)
            uppercase_var=$(echo "${other_worker}" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
            var_name="${uppercase_var}_URL"
            
            if grep -q "$var_name" "$toml_file"; then
                new_url="${worker_urls[$other_worker]}"
                echo "Updating $var_name to $new_url"
                
                # Update the URL in the toml file
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS uses BSD sed
                    sed -i '' "s|$var_name = \".*\"|$var_name = \"$new_url\"|g" "$toml_file"
                else
                    # Linux uses GNU sed
                    sed -i "s|$var_name = \".*\"|$var_name = \"$new_url\"|g" "$toml_file"
                fi
                
                needs_update=true
            fi
        done
    fi
    
    # If updates were made, deploy the worker to apply changes
    if [ "$needs_update" = true ]; then
        echo -e "Deploying ${YELLOW}$worker_name${NC} to apply URL updates..."
        (cd "$worker_path" && bunx wrangler deploy)
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Successfully deployed $worker_name with updated URLs${NC}"
        else
            echo -e "${RED}❌ Failed to deploy $worker_name${NC}"
        fi
    else
        echo -e "${GREEN}No URL updates needed for $worker_name${NC}"
    fi
done

echo -e "\n${GREEN}✅ Worker domain setup process completed!${NC}"
echo -e "${YELLOW}IMPORTANT: These domains are now configured for your workers:${NC}"

for i in "${!worker_names[@]}"; do
    echo -e "${YELLOW}${worker_names[$i]}${NC}: ${GREEN}${worker_urls[${worker_names[$i]}]}${NC}"
done 