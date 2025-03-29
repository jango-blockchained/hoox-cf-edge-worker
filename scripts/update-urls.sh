#!/bin/bash

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=============================================${NC}"
echo -e "${YELLOW}  Update Worker URLs for Production          ${NC}"
echo -e "${YELLOW}=============================================${NC}"
echo

# Navigate to the root directory
cd "$(dirname "$0")/.." || {
    echo -e "${RED}Error: Could not navigate to the root directory.${NC}"
    exit 1
}

# Get list of all worker directories
worker_dirs=$(find workers -maxdepth 1 -type d -not -path "workers" | sort)
worker_names=()

# Define the base custom domain pattern
read -p "Enter your Cloudflare account subdomain (e.g., 'cryptolinx'): " account_subdomain

if [ -z "$account_subdomain" ]; then
    echo -e "${RED}Error: Account subdomain is required.${NC}"
    exit 1
fi

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
done

# Map to store worker URLs for cross-references
declare -A worker_urls

# Populate the map with URLs
for worker_name in "${worker_names[@]}"; do
    worker_urls["$worker_name"]="https://${worker_name}.${account_subdomain}.workers.dev"
    echo -e "Worker: ${YELLOW}$worker_name${NC} -> URL: ${BLUE}${worker_urls[$worker_name]}${NC}"
done

echo
# Confirm before proceeding
read -p "Are these URLs correct? This will update the worker configurations. (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

# Now update wrangler.toml files
echo -e "\n${BLUE}Updating worker configurations...${NC}"

for worker_name in "${worker_names[@]}"; do
    worker_path="workers/$worker_name"
    toml_file="$worker_path/wrangler.toml"
    
    echo -e "\n${BLUE}Configuring worker: ${YELLOW}$worker_name${NC}"
    
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
                echo "Updating $var_name to $new_url in wrangler.toml"
                
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
    
    if [ "$needs_update" = true ]; then
        echo -e "${GREEN}✅ Updated URLs in wrangler.toml for $worker_name${NC}"
    else
        echo -e "${GREEN}No URL updates needed for $worker_name${NC}"
    fi
done

# Ask if they want to deploy the changes
echo
read -p "Do you want to deploy these changes to all workers? (y/n): " deploy_confirm
if [[ "$deploy_confirm" == "y" || "$deploy_confirm" == "Y" ]]; then
    echo -e "\n${BLUE}Deploying workers with updated configurations...${NC}"
    
    for worker_name in "${worker_names[@]}"; do
        worker_path="workers/$worker_name"
        
        echo -e "\nDeploying ${YELLOW}$worker_name${NC}..."
        cd "$worker_path" || {
            echo -e "${RED}Error: Could not navigate to $worker_path.${NC}"
            continue
        }
        
        # Deploy using wrangler
        bunx wrangler deploy
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Successfully deployed $worker_name with updated URLs${NC}"
        else
            echo -e "${RED}❌ Failed to deploy $worker_name${NC}"
        fi
        
        cd - > /dev/null
    done
fi

echo -e "\n${GREEN}✅ Production URL configuration completed!${NC}"
echo -e "${YELLOW}IMPORTANT: These URLs are now configured for production:${NC}"

for worker_name in "${worker_names[@]}"; do
    echo -e "${YELLOW}${worker_name}${NC}: ${GREEN}${worker_urls[$worker_name]}${NC}"
done

echo -e "\n${YELLOW}NOTE: Make sure your workers are published with 'wrangler deploy'${NC}"
echo -e "${YELLOW}      You can use 'scripts/deploy-all.sh' to deploy all workers${NC}" 